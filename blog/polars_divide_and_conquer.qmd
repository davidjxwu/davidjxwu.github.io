---
title: "Solving a Large Problem"
date: '2023-07-27'
categories: ['python']
---

Recently, I've been working on a large table of data, where we need to do a relatively expensive operation on a few rows which are determined at runtime. By large, I mean large by academic standards - there are only in the order of 20 million records, and we're only dealing with a single 4-column table.

The operation in question revolves around fixing temporal overlaps in the table.
The schema looks roughly like this:

| Column Name | Individual | Auxiliary Information | Time Start | Time End |
|:-----------:|:----------:|:---------------------:|:----------:|:--------:|
| Column Type | Int64 | Str | Datetime | Datetime |


where an overlap is where, for the same Identifier, there is a temporal overlap between the start and end time of one record and the start and end time of another record.

For example, there is an overlap in the following fragment:

| Record | Individual | Aux Info | Time Start | Time End |
|--:|:---:|:---:|:----:|:----:|
| 1 | 1 | A | 2000-01-01 0900 | 2000-01-02 0900 |
| 2 | 1 | B | 2000-01-01 2100 | 2000-01-02 2100 |

and we can fix this by moving the end date of record 1:

| Record | Individual | Aux Info | Time Start | Time End |
|--:|:---:|:---:|:----:|:----:|
| 1 | 1 | A | 2000-01-01 0900 | **_2000-01-01 2100_** |
| 2 | 1 | B | 2000-01-01 2100 | 2000-01-02 2100 |

My first attempt at this, which "worked" for a much smaller table, was to explicitly extract the records for each individual iterate through their start and end times to see where they were, and then stitch them back together. This was hugely inefficient interms of both computation time and memory.
The only viable strategy for fixing these overlaps over a large dataset is to compare succesive records for an individual, so we may end up in circumstances where fixing one overlap between say rows 2 and 3 generates another overlap between rows 2 and 4.
In these cases, we need to iterate the overlap fixing procedure multiple times until we are free of overlaps.

Roughly, the procedure would be to, on the entire table:
- Look ahead one row
- See if there was an overlap
- Move the start and end times to resovle the overlaps

So, off I go, implementing this algorithm, and when I apply it to the large data base I get timings of each iteration, which look like:

```
Iteration 1 : 20.71 s  217409 overlaps
Iteration 2 : 11.22 s    8936 overlaps
Iteration 3 : 10.82 s    5354 overlaps
Iteration 4 : 10.94 s    4237 overlaps
Iteration 5 : 10.11 s    3545 overlaps
Iteration 6 : 10.97 s    3033 overlaps
Iteration 7 : 10.47 s    2376 overlaps
Iteration 8 : 10.73 s    2005 overlaps
Iteration 9 : 10.78 s    1622 overlaps
Iteration 10: 10.36 s    1317 overlaps
Iteration 11: 10.56 s    1080 overlaps
Iteration 12: 10.33 s     913 overlaps
...
```

which is good, but a bit slow. We may need to iterate a few hundred times, just due to the nature of the fixing procedure, and I didn't want to wait a few hours for this thing to finish.

To proceed any further, we need to make a key observation:
> If an individual does not have any overlaps in their records, then an iteration of the overlap fixing procedure will cause them to have any overlaps.

This is important, since the "look ahead" operation is relatively expensive if it needs to be applied 20 million times. It would be much better if we _only performed the overlap fixing preocedure on the records that have overlaps_ (obvious I know). 

To do this, we can add in an operation before each iteration that finds the individuals that have no overlaps, and "removes" them. We get the following algorithm:

1. Initialise an empty list `clean_records`
2. Iterate a fixed number of times:
   1. Split the dataframe into two, one with individuals without overlaps `clean_df`, and one with individuals that do have overlaps `dirty_df`
   2. Append `clean_df` to `clean_records`
   3. If `dirty_df` is empty (all individuals have no overlaps), break out of the loop early
   4. Look ahead 1 row for each record in `dirty_df` to find overlaps
   5. Adjust start and end times to fix overlaps
3. Concatenate together all `clean_records`

This successively reduces the size of the dataframe going into the loop, which thus reduces the computation time of each iteration.
Looking at the processing times, we see that this is the case:

```
Iteration 1 : 22.67 s  217409 overlaps
Iteration 2 :  0.82 s    8936 overlaps
Iteration 3 :  0.32 s    5354 overlaps
Iteration 4 :  0.25 s    4237 overlaps
Iteration 5 :  0.22 s    3545 overlaps
Iteration 6 :  0.14 s    3033 overlaps
Iteration 7 :  0.11 s    2376 overlaps
Iteration 8 :  0.08 s    2005 overlaps
Iteration 9 :  0.09 s    1622 overlaps
Iteration 10:  0.06 s    1317 overlaps
Iteration 11:  0.05 s    1080 overlaps
Iteration 12:  0.04 s     913 overlaps
```

One possible negative side effect is that there will be transient spikes in the memory usage in garbage-collected langauges, such as Python, since the split dataframes may be copies of the original pre-split dataframe, instead of views.

This approach roughly belongs to the family of _divide-and-conquer_ strategies. We split a large problem into smaller problems that can then themselves be split up, or solved through simple appraoches.
Here, we make out choice of split very carefully, so that one branch of the division is always trivially solved (no-op), and the other branch takes the majority of the computational expense.

These approaches are always valuable in solveing large problems, since we reduce the size and complexity of the problem we have to tackle significantly. This also means that even some inefficiencies can be allowed - an O(exp(N)) isn't really all that bad when N is small, after all.