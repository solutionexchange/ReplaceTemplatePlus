<% Option Explicit
Dim Filename
Filename = "staging/" & Request.Form("FileName")
Const ForReading = 1, ForWriting = 2, ForAppending = 3
Const TristateUseDefault = -2, TristateTrue = -1, TristateFalse = 0

' Create a filesystem object
Dim FSO
Set FSO = server.createObject("Scripting.FileSystemObject")

' Map the logical path to the physical system path
Dim Filepath
Filepath = Server.MapPath(Filename)

If FSO.FileExists(Filepath) Then
	Dim TextStream
    Set TextStream = FSO.OpenTextFile(Filepath, ForReading, False, TristateUseDefault)

    ' Read file in one hit
    Dim Contents
    Contents = TextStream.ReadAll
    Response.Write(Contents)
    TextStream.Close
    Set TextStream = nothing
    
	FSO.DeleteFile(Filepath)
Else
    Response.Write "<h3><i><font color=red> File " & Filename & " does not exist</font></i></h3>"
End If


Set FSO = Nothing
%>