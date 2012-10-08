SET FUNCDIR=C:\cygwin\home\ctscoll\fisher_v0.8\Function
SET INCDIR=C:\cygwin\home\ctscoll\fisher_v0.8\Include
SET VXDIR=C:\cygwin\home\ctscoll\fisher_v0.8\Bin

del *.vx
FOR %%f IN (*.vs) DO vlc6w -e -u -v1 %%f
