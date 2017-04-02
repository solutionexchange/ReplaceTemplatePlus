<html>
<head>
	<%
		strLoginGuid = session("loginguid")
		strSessionKey = session("sessionkey")
		strContentClassGuid = session("TreeGuid")
		strTemplateGuid = session("TemplateGuid")
		strTemplateVariantGuid = session("TemplateVariantGuid")
	%>
	<meta http-equiv="expires" content="-1"/>
	<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
	<meta name="copyright" content="2010, Web Solutions Group"/>
	<title>RedDot CMS - Replace Template Plus</title>
	<style type="text/css">
		body
		{
			padding: 0px 7px 0px 7px;
		}
		
		.headline
		{
			text-align: center;
			font-size: 120%;
			font-weight: bold;
			padding: 5px;
			background-color: #484848;
			color: #FFFFFF;
		}
		
		.content
		{
			padding: 10px;
			background-color: #EFEFEF;
			border: 1px solid #DEDEDE;
			margin-bottom: 20px;
		}
		
		.attention
		{
			background-color: #EEF66C;
		}

		a.positivebutton
		{
			background-color:#F5F5F5;
			border: 1px solid #DEDEDE;
			color: #529214;
			padding: 5px 10px 5px 10px;
			text-decoration: none;
			font-weight: bold;
			float: right;
		}
		
		a.positivebutton:hover
		{
			background-color:#C6C6C6;
		}
	</style>
	<script type="text/javascript" src="js/jquery-1.3.2.min.js"></script>
	<script type="text/javascript" src="js/jquery.blockUI.js"></script>
	<script type="text/javascript" src="js/jquery.form.js"></script>
	
	<script type="text/javascript">
		$(document).ready(function() { 
			$("#uploadbutton").click(function() {
				$.blockUI({
					css: { 
						border: "none", 
						padding: "15px",
						backgroundColor: "#000", 
						"-webkit-border-radius": "10px", 
						"-moz-border-radius": "10px", 
						opacity: .5, 
						color: "#fff" 
					}
				});
			
				uploadFile("templateuploadform");
			});
		});
		
		function uploadFile(formID)
		{
			// bind form using ajaxForm 
			$("#" + formID).ajaxForm({ 
				// dataType identifies the expected content type of the server response 
				dataType:  "txt",
				beforeSubmit: validateFormData,
				// success identifies the function to invoke when the server response 
				// has been received
				success: fileUploaded
			});
			
			$("#" + formID).submit();
		}
		
		function validateFormData()
		{
			var FileName = $("#templateinput").val();
			var FileExtLoc = FileName.search(/(.)*?\.rdtp/);

			if(FileExtLoc < 0)
			{
				$.unblockUI();
				
				$("#formarea").addClass("attention");
				return false;
			}

			$("#formarea").removeClass("attention");
			
			return true;
		}
		
		function fileUploaded(FileName)
		{
			readFile(FileName);
		}
		
		function readFile(FileName)
		{
			$.post("readanddelete.asp", { FileName: FileName },
			function(data){
				 ParseTemplateExport(data);
			});
		}

		function ParseTemplateExport(TemplateExportText)
		{
			var pattrTemplateProperties = "<!--ioBegin TemplateProperties-->((.|\r\n)*?)<!--ioEnd TemplateProperties-->";
			var pattrTemplateProperties_fileextension = "fileextension=\"((.)*?)\"";
			var pattrTemplateProperties_name = "name=\"((.)*?)\"";
			var pattrElementData = "<!--ioBegin ElementData-->((.|\r\n)*?)<!--ioEnd ElementData-->";
			var pattrTemplateSourceCode = "<!--ioBegin TemplateSourceCode-->((.|\r\n)*?)<!--ioEnd TemplateSourceCode-->";
		
			var TemplateProperties = TemplateExportText.match(pattrTemplateProperties)[1];
			var TemplateProperties_fileextension = TemplateProperties.match(pattrTemplateProperties_fileextension)[1];;
			var TemplateProperties_name = TemplateProperties.match(pattrTemplateProperties_name)[1];;
			var ElementData = TemplateExportText.match(pattrElementData)[1];
			var TemplateSourceCode = TemplateExportText.match(pattrTemplateSourceCode)[1];
			
			matchGuidToElements(TemplateProperties_fileextension, TemplateProperties_name, ElementData, TemplateSourceCode);
		}
		
		function matchGuidToElements(TemplateFileExtension, TemplateName, ElementData, TemplateSourceCode)
		{
			// list all existing elements
			var FullRql = padRQLXML("<PROJECT><TEMPLATE action=\"load\" guid=\"<%=strTemplateGuid%>\"><ELEMENTS childnodesasattributes=\"0\" action=\"load\"/><TEMPLATEVARIANTS action=\"list\"/></TEMPLATE></PROJECT>");
			$.post("rqlaction.asp", { rqlxml: FullRql }, function(data){
				if($(data).find("ERRORTEXT").length > 0)
				{
					alert("Error: " + $(data).find("ERRORTEXT").text());
				}
				else
				{
					$(data).find("ELEMENT").each(function (i){
						var ElementName = $(this).attr("eltname");
						var ElementGuid = $(this).attr("guid");
						
						var SearchString = "eltname=\"" + ElementName + "\"";
						var ReplaceString = SearchString + " guid=\"" + ElementGuid + "\"";
						ElementData = ElementData.replace(SearchString, ReplaceString);
					});
					
					replaceContentClass(TemplateFileExtension, TemplateName, ElementData, TemplateSourceCode);
				}
			});
		}
		
		function replaceContentClass(TemplateFileExtension, TemplateName, ElementData, TemplateSourceCode)
		{
			var PartialRql = "";
			PartialRql += "<PROJECT>";
			PartialRql += "<TEMPLATE ignoreguids=\"1\" languagevariantid=\"ENG\" action=\"save\" guid=\"<%=strTemplateGuid%>\">";
			PartialRql += "<ELEMENTS>"
			PartialRql += ElementData;
			PartialRql += "</ELEMENTS>";
			PartialRql += "<TEMPLATEVARIANT guid=\"<%=strTemplateVariantGuid%>\" fileextension=\"" + TemplateFileExtension + "\" name=\"" + TemplateName + "\">";
			PartialRql += encodeHTML(TemplateSourceCode);
			PartialRql += "</TEMPLATEVARIANT>";
			PartialRql += "</TEMPLATE>";
			PartialRql += "</PROJECT>";
			
			var FullRql = padRQLXML(PartialRql);
			
			$.post("rqlaction.asp", { rqlxml: FullRql }, function(data){
				if($(data).find("ERRORTEXT").length > 0)
				{
					alert("Error: " + $(data).find("ERRORTEXT").text());
				}
				else
				{
					$.unblockUI();
					
					// close this window
					window.opener.ReloadTreeSegment();
					window.opener = "";
					self.close();
				}
			});
		}
		
		function encodeHTML(text) 
		{
			text = text.replace(/&/g,"&amp;");
			text = text.replace(/>/g,"&gt;");                                           
			text = text.replace(/</g,"&lt;");        
			text = text.replace(/'/g,"&apos;");	
			text = text.replace(/"/g,"&quot;");
			
			return text;
		}
		
		function padRQLXML(innerRQLXML)
		{
			return "<IODATA loginguid=\"<%= strLoginGuid %>\" sessionkey=\"<%= strSessionKey%>\">" + innerRQLXML + "</IODATA>";
		}
	</script>
</head>
<body>
	<div class="headline">
		Replace Template Plus
	</div>
	<div class="content">
		Replace Template with option to overwrite existing element settings
	</div>

	<div class="headline">
		Please specify a template export file (.rdtp)
	</div>
	<div id="formarea" class="content">
		<form id="templateuploadform" method="post" enctype="multipart/form-data" action="upload.asp">
			<input type="file" id="templateinput" name="templateinput" accept="*.rdtp" style="width: 90%">
		</form>
	</div>
	<a class="positivebutton" href="#" id="uploadbutton">Upload</a>
</body>
</html>