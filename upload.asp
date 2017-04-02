<%@ Language=VBScript %>
<% 
Option Explicit
Response.Expires = -1
Server.ScriptTimeout = 600
%>
<!-- #include file="freeaspupload.asp" -->
<%
' ****************************************************
' Change the value of the variable below to the pathname
' of a directory with write permissions, for example "C:\Inetpub\wwwroot"
	Const StagingFolderPath = "staging"
	Dim uploadsDirVar
	uploadsDirVar = Server.MapPath(StagingFolderPath) 
' ****************************************************

Function SaveFiles
    Dim Upload, fileName, fileSize, ks, i, fileKey

    Set Upload = New FreeASPUpload
    Upload.Save(uploadsDirVar)

	' If something fails inside the script, but the exception is handled
	If Err.Number<>0 Then Exit Function

    SaveFiles = ""
    ks = Upload.UploadedFiles.keys
    If (UBound(ks) <> -1) Then
        For Each fileKey In Upload.UploadedFiles.keys
			If ValidateFile(Upload.UploadedFiles(fileKey).FileName) <> "" Then
				SaveFiles = SaveFiles & Upload.UploadedFiles(fileKey).FileName
			End If
        Next
    Else
		' The file name specified in the upload form does not correspond to a valid file in the system.
        SaveFiles = ""
    End If
End Function

function ValidateFile(FileName)
	Dim FSO
	Set FSO = server.createObject("Scripting.FileSystemObject")
	
	Const FileExt = "rdtp"
	
	Dim FuncRet
	FuncRet = FileName
	
	If FSO.GetExtensionName(FileName) <> FileExt Then
		FSO.DeleteFile(uploadsDirVar & "/" & FileName)
		FuncRet = ""
	End If
	
	Set FSO = Nothing
	
	ValidateFile = FuncRet
End Function

Response.Write SaveFiles()
%>
