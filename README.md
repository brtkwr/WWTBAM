    W     W W     W TTTTTTT BBB    AAA  M     M
    W     W W     W    T    B  B  A   A M M M M
    W  W  W W  W  W    T    BBBB  AAAAA M  M  M
    W W W W W W W W    T    B   B A   A M     M
    W     W W     W    T    BBBB  A   A M     M

# Foreword

This is one of the first ever program that I wrote in 2002 implemented in QBasic as I was learning to program. It tries its best to imitate `who wants to be a millionare` TV game show.

There are aspects of it which I now think are hilarious which is why I am sharing it so do give it a go.

You will probably need a DOS emulator like [Boxer] to get it working on OSX. I have not had a chance to deploy it on the latest versions of Windows and Linux so do let me know how you get on if you do.

B, 2018

[Boxer]: http://www.boxerapp.com

# Original Terms and Conditions

Following are the terms and conditions that you will have to accept in order to run WWTBAM !!!

This program is a shareware. This means:

- This program is a registered trademark of KGOI (Kunwar Group Of Industries) !!
- And this program was officially allowed by the company to be shared among the units !!
- As this program is a shareware, any type of buying or selling business with this program will be considered illegal by the law !!!
- If any damages occur to your system because of this program then we are not responsible. But we got 80% confidence that it won't damage !!!
- You will also have to supply with the necessary program requirements to continue with the setup !! They are :
    - A good monitor [17 inch(best)]
    - A good keyoard
    - At least 8 MB of total RAM
    - OS (DOS, Win 3.1/9x/2k/XP/NT)
    - Pentium or higher class CPU
    - Knowledge of the user

If you accept the terms and conditions given above then you can continue with the setup process !!!

During the setup process, while selecting the installation directory, you may face some sort of difficulties. But it is as easy as you think that it is hard !!! But for this, you should have learnt a little bit of DOS. If you don't know it then you can consult some of your relatives of colleagues of friends who know DOS.

You can then continue and install the program. But you may sometime get some errors at the setup process. They may be caused because of either of the following reasons. They are as follows:

- If you select a directory with less that at least 1 MB of disk space.
- If you select a directory of a read only media.
- If you select the floppy disk as the installation directory with no floppy in it or if the floppy is damaged.

These are the reasons which may cause errors in the installation process. If you have cared for this errors and run the setup process and you get error, please report it to me on my website http://kunwar.funurl.com (***doesn't exist anymore***) or mail me on bharatkunwar@hotmail.com (***no longer in use***).

Thank-you for choosing the software.
# Source reconstruction (2026)

The original QBasic source was lost, so it was reverse engineered back out of `WWTBAM.EXE`:

- [`src/WWTBAM.BAS`](src/WWTBAM.BAS) - reconstructed QuickBASIC 4.5 source of the main game (all strings, money ladders, lifeline logic and DATA blocks recovered verbatim from the binary).
- [`docs/REVERSE_ENGINEERING.md`](docs/REVERSE_ENGINEERING.md) - full write-up: the `.BBK` file masquerade, question bank format, registration scheme, money ladders and screenshots of the original EXE running in DOSBox.
- [`assets/`](assets) - the data files unmasked into their true formats (fonts, the hidden BMP, question banks as plain text).
