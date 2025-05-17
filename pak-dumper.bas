#INCLUDE "dir.bi"

' Wrapper application for bulk extraction from PAK files from a directory
' Would not be possible without code developed by http://www.thealmightyguru.com/Wiki/index.php?title=Main_Page
' Original description
'  This program will extract the files stored in a Westwood PAK file used in various games in the first half of the 1990s.
'  There are three versions of the PAK file. Version 1 was used only in Eye of the Beholder 1. To determine the 
'  end of the header, just wait until the file pointer equals the position of the first file. The last file offset is the 
'  length of the file. Version 2 was first used in Dune II. It's header ends when the file offset is zero (0x0000). 
'  Version 3 was first used in The Legend of Kyrandia 2. It has an additional empty file name with a file offset so you 
'  can easily determine the size of the last file rather than relying on the length of the file, like in version 2.

Dim RootDirectory AS STRING 
Dim RootExportDirectory AS STRING 
Input "Root Director for PAK files: ", RootDirectory
Input "Root Output Folder: ", RootExportDirectory

CHDIR RootDirectory

DECLARE SUB listFiles (filespec AS STRING, attrib AS INTEGER, RootExportDirectory AS STRING)
DECLARE SUB pakExtract(ExportFolder AS STRING, filename AS STRING)

SUB pakExtract(ExportFolder AS STRING, PAKFile AS STRING)
   Dim As UInteger<32> FileStart(1000)
   Dim As String   FileName(1000)
   Dim As UInteger<32> Position
   Dim As String   Char
   Dim As UInteger FileCount = 0
   Dim As UInteger FileNo
   Dim As ULong    FileSize
   Dim As UInteger ByteNo
   
   Open PAKFile For Binary As #1
   
   ' Loop through the header.
   Do
       ' 4-byte file start position.
       Get #1, , FileStart(FileCount)

       Position = Seek(1)

       ' Trap for version 2 and 3 PAK files.
       If FileStart(FileCount) = 0 Then
           Exit Do
       Else
           ' Trap for version 1 PAK files.
           If (Position - 1) = FileStart(0) Then
               FileCount = FileCount + 1
               Exit Do
           Else
               ' Read the file name until we hit a null.
               FileName(FileCount) = ""
               Do
                   Char = " "
                   Get #1, , Char
                   If Asc(Char) <> 0 Then
                       FileName(FileCount) = FileName(FileCount) + Char
                   End If
               Loop While Asc(Char) <> 0

               FileCount = FileCount + 1
           End If
       End If
   Loop
   FileCount = FileCount - 1
   For FileNo = 0 To FileCount
    ' Read the previous file from the PAK.
    
    ' Get the file size.
    If FileNo = FileCount Then
        ' Trap for version 1 and 2 PAK files.
        FileSize = LoF(1) - FileStart(FileNo)
    Else
        FileSize = FileStart(FileNo + 1) - FileStart(FileNo)
    End If

    Print Using "    \            \ ###) File: \            \ Offset: ########,,   Size: ########,"; PAKFile; FileNo; FileName(FileNo); FileStart(FileNo); FileSize

    ' Trap for version 3 PAK files.
    If FileSize > 0 Then
        ' Create a buffer to store the next file.
        ReDim As Byte FileData(0 To FileSize)
        
        ' Load the file from the PAK into the buffer.
        Seek 1, FileStart(FileNo) + 1
        For ByteNo = 0 To (FileSize - 1)
            Get #1, , FileData(ByteNo)
        Next ByteNo
    
        ' Save the buffer to the export folder.
        Open ExportFolder + "\" + FileName(FileNo) For Binary As #2
        For ByteNo = 0 To (FileSize - 1)
            Put #2, , FileData(ByteNo)
        Next ByteNo
        Close #2
    End If
   Next FileNo

'Print "Finished."
Close #1
END SUB

SUB listFiles (filespec AS STRING, attrib AS INTEGER, RootExportDirectory AS STRING)
   DIM PAKFile AS STRING
   DIM ExportFolder AS STRING
   PAKFile = DIR(filespec, attrib)
   DO WHILE LEN(PAKFile) > 0
      IF (right(PAKFile,3) = "PAK" OR right(PAKFile,3) = "VRM") THEN
         ExportFolder = RootExportDirectory & "\" & PAKFile
         MKDir(ExportFolder)
         PRINT
         PRINT "Extracting PAK file... " & PAKFile
         PRINT
         pakExtract(ExportFolder, PAKFile)
      ELSE
         PRINT
         PRINT "Skipping non-PAK file... " & PAKFile
         PRINT
      END IF
      PAKFile = DIR()
   LOOP
END SUB

listFiles "*", fbArchive, RootExportDirectory
