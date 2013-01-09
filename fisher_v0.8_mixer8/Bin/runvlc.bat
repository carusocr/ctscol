SET FUNCDIR=..\Function
SET INCDIR=..\Include
SET VXDIR=..\Bin

del *.vx
FOR %%f IN (*.vs) DO vlc6w -e -u -v1 %%f
