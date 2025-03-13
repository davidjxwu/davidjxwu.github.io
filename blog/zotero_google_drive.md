---
title: "Zotero with Google Drive for Cheapskates like Me"
date: "2023-05-03"
categories: [software]
# draft: yes
---

A few years ago, in the middle of my PhD, I decided to move form Mendeley to Zotero, mostly because the browser plugin was hanging a lot on a particular publisher's site (I can't remember which one).
Zotero was a very familiar system, but it had one drawback: because it was open-source freeware, the developers needed to monetise it somehow (rightfully), and they decided to offer cloud storage at a very reasonable price.
For a cheapskate graduate student like me, I didn't want to part with my paltry $20 a year.
I stumbled on a blog by [Tom Saunders](https://tomsaunders.me) that detailed how to setup Zotero to use Google Drive as the storage medium. This blog post has since been lost to the sands of internet time, though I do know it's archived somewhere.
Here, I aim to ~~plagiarise~~ reproduce that post, with a few up-to-date hints on how to make this pseudo-cross-platform.

> If you are in the financial position to do so, **just pay for Zotero cloud storage**. It's much easier to deal with, and not really all that expensive. Better yet, you'd be supporting the developers that even Elsevier leech off.

The overall idea of this setup is the following:
- Have Zotero sync the entries in your library
- Use Google Drive to sync a local folder on your computer with Google Drive's cloud storage
- Use Zotfile to point Zotero at the local folder that's synced wtih Google Drive

## Prereqs

1. Zotero installed on your system (or some app that can sync with Zotero)
2. A Zotero account for syncing
3. A Google account with access to Google Drive

## 1. Installing Zotfile

[Zotfile](http://zotfile.com/) is an addon for Zotero that will be the way we get Zotero to point to a local directory for file syncing.
Download the addon file, and install it following the [install instructions](http://zotfile.com/#how-to-install--set-up-zotfile).

In Zotero, look for `Tools` in the top menu, and then `Add-ons`. Click the settings cog in the top right and select `Install Add-on From File`. Select the zotfile `.xpi` file that you downloaded.

## 2. Installing Google Drive

We will now setup Google Drive syncing. As of the writing of this post, this is a working method, but Google has a [bad habit of sunsetting things for no good reason](https://killedbygoogle.com/).
So try your best to navigate this future reader.

### Setting up Google Drive

We need a folder that we sync specifically for Zotero. 
The simple solution is to create a folder, like `Zotero`, in the root of your Drive. Going forward, I'll assume this is what you've done, so adjust the paths accordingly.

### Windows

Download [Drive for desktop](https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe), and follow the on-screen instructions.
This will set up a new drive on your computer (typically the `G:` drive) that will be a 'synced' version of your entire Google Drive.
> It looks like the log-in process is broken on Firefox, because Google believes in [an open internet for all](https://www.youtube.com/watch?v=_p6tvs-qjpA&t=6s). 

In the preferences section of the Google Drive desktop application, you can choose to switch to "mirroring" your Google Drive instead of "streaming" if you typically like to work offline. This will make actual copies of the files in your Drive on your disk. In "streaming" mode, files are downloaded as needed. I suggest staying in "streaming" mode for most users.

### Linux

Install [google-drive-ocamlfuse](https://github.com/astrada/google-drive-ocamlfuse).

The command to mount is:

```
google-drive-ocamlfuse [/mount/point]
```

As usual, add the mount command to `~/.profile` so that it automatically is called when you login to your GUI (or whatever your flavour of *nix torture requires).

### Mac
 
Probably the same as Windows.

### Android

There are various apps that allow you to mirror files onto your local device. The built-in Google Drive app doesn't do this, so you can't use it to set up this process.

## 3. Configuring Zotero

Open Zotero and find `Edit` in the top menu, then click `Preferences`.
We will be adjusting the settings marked below:

![Zotero Settings, General tab: File Handling - disable automatically taking snapshots of webpages; and Miscellaneous - disable automatically tagging items](/images/blog/zotero_google_drive/zotero_settings_general.png)  
This is purely optional.

![Zotero Settings, Sync tab: Data Syncing - link your account, enable Sync automatically, disable Sync full-text content; and File Syncing - disable all](/images/blog/zotero_google_drive/zotero_settings_sync.png)  
This performs the library syncing. We turn off the file syncing, since we will handle that with Zotfile.

![Zotero Settings, Search tab: Full-text Cache: set the max characters to 999999, set the max pages to 999](/images/blog/zotero_google_drive/zotero_settings_search.png)  
This simply allows us to search our library entries like a database. Increasing these values past the defaults just makes it work on a larger range of (larger) files.

![Zotero Settings, Advanced tab: Files and Folders tab - Linked Attachment Base Directory - change the base directory to the local Google Drive folder that contains the attachments](/images/blog/zotero_google_drive/zotero_settings_advanced.png)  
With a Windows OS install, the path will look like this - make sure that this folder is the one you created.

Hit OK.

## 4. Configuring Zotfile

In Zotero, go to `Tools` in the top menu, then select `Zotfile Preferences`.

![Zotfile, General: select Custom Location, and set it to the same directory as the one in the Zotero settings / Advanced from above](/images/blog/zotero_google_drive/zotfile_general.png)
Make sure that the directory you choose is the same as the one in the Advanced panel of the Zotero settings we set above.

![Zotfile Renaming Rules: disable using Zotero to rename, turn off truncating](/images/blog/zotero_google_drive/zotfile_renaming.png)
Changing the delimiter is optional - if you're doing this on multiple devices, make sure it's consistent. The maximum title length just makes sure that mothing is cut off.

## Conclusion

You're now all set! Now, whenever you save citations with Zotero, the pdfs will be placed on your local drive, and synced to your Google Drive.

Some final notes:

- I tend to force the syncing of files with the `Manage Attachments > Rename and Move` action in the right-click context menu of each entry. This just makes sure that the movement of the local file happens.
- If the browser connector doesn't find a file for some reason, just download the file, and add it to the entry with `Add Attachment >  Attach Link to File` (right-click context menu), then rename it with `Manage Attachments > Rename and Move`, and it will sync.
- Again, please just pay for the Zotero cloud storage and support the devs. Use this as a final resort - all the components here, particularly on Google's side, are very fragile.