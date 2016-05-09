INCLUDE irvine32.inc

.DATA 
	maxLength EQU 10
	stringISBN BYTE maxLength DUP(?), 0
	filePath BYTE "E:\\ISBN-Test-Input.txt", 0
	tmpFileHandle HANDLE ?
	ISBNValues BYTE maxLength DUP(?)
	header BYTE "THE ISBN ", 0
	validMessage BYTE " is valid", 0
	invalidMessage BYTE " is not valid", 0
	fileStructureGarbage BYTE 2 DUP(?), 0

.CODE
;----------------------------------------------
;Main Procedure
;----------------------------------------------
main PROC
	MOV EDX, OFFSET filePath
	CALL OpenFile
	CMP EAX, 0									;Check if error happened while opening the file
	JE EndProgram	

	MOV tmpFileHandle, EAX
	ReadAllFile:
		PUSH ECX

		MOV EAX, tmpFileHandle
		MOV EDX, OFFSET stringISBN
		MOV ECX, maxLength
		CALL ReadOpenedFile

		CMP EAX, 0								;This comparison tells if the file was empty from the beginning or if error happened while reading from file
		JE EndProgram

		MOV AL, [EDX]
		CALL IsDigit							;Check if the ISBN has numeric value and not empty
		JNZ EndProgram

		MOV EAX, tmpFileHandle
		MOV EDI, OFFSET ISBNValues
		CALL FillValuesArray
		CALL ValidateISBN
		CALL DisplayResult

		MOV EAX, tmpFileHandle
		MOV EDX, OFFSET fileStructureGarbage
		MOV ECX, 2
		CALL CheckIfEOF
		CMP EAX, 0								;This comparison tells whether I reached the end of file or not
		JE EndProgram

		POP ECX
		JMP ReadAllFile

	EndProgram:
		CALL CloseFile
EXIT
main ENDP

;-----------------------------------------------
;Calculates:	Opens an existing file for input
;Receives:		EAX contains the file handle
;Returns:		IF the file handle is valid: 
;					1- EAX contains the file handle
;					2- A copy of EAX is stored into memory buffer named "tmpFileHandle"
;				ELSE:
;					1- EAX contains 0
;					2- A string contains the code and description of error is displayed
;----------------------------------------------
OpenFile PROC USES ECX EDX 

	CALL OpenInputFile				
	CMP EAX, INVALID_HANDLE_VALUE
	JNE Quit

	Error:
		CALL WriteWindowsMsg					;Display error message
		MOV EAX, 0
	Quit:
	RET

OpenFile ENDP
 
;-----------------------------------------------
;Calculates:	Reads an input disk file into a memory buffer
;Receives:		EAX contains the file handle,
;				EDX contains offset of string of ISBN,
;				ECX contains length of ISBN code
;Returns:		EAX contains 0 if file is empty from the beginning or the file handle is invalid
;----------------------------------------------
ReadOpenedFile PROC USES ECX EDX

	CALL ReadFromFile	
	JNC Valid

	Error:
		CALL WriteWindowsMsg					;Display error message
		MOV EAX, 0
	Valid:
	RET

ReadOpenedFile ENDP

;-----------------------------------------------
;Calculates:	Splits the given file record (string) into digits and fills an array with the numeric values
;Receives:		EDX contains ISBN string offset,
;				EDI contains ISBN values array offset,
;				ECX contains length of ISBN code
;Returns:		Nothing
;-----------------------------------------------
FillValuesArray PROC USES EAX ECX EDX EDI

	FillArray:
		MOV AL, [EDX]
		CALL ConvertToInteger
		MOV [EDI], AL
		INC EDX
		INC EDI
	LOOP FillArray
	RET

FillValuesArray ENDP 

;-----------------------------------------------
;Calculates:	Converts a char to an integer value to perform arithmetic operations on it
;Receives:		AL contains char to be converted into an integer
;Returns:		AL contains the numeric value of the character
;-----------------------------------------------
ConvertToInteger PROC

	CMP AL, 'X'
	JE XValue

	SUB AL, 48									;Subtract 48 to get the integer value (ASCII value)
	JMP Next

	XValue:
		MOV AL, 10
	Next:
	RET

ConvertToInteger ENDP 

;-----------------------------------------------
;Calculates:	Checks whether the ISBN is valid or not
;Receives:		EDI contains offset of the array of values of the ISBN code
;				ECX contains length of ISBN code
;Returns:		EAX = 1 if valid, EAX = 0 if not valid
;-----------------------------------------------
ValidateISBN PROC USES EBX ECX EDX ESI

	MOV EBX, 0
	MOV ESI, ECX								;Set ESI with length of ISBN code

	OnISBNValues:
		MOV EDX, 0
		MOVZX EAX, BYTE PTR [EDI]
		MUL ESI
		ADD EBX, EAX							;Store summation of values in EBX
		DEC ESI
		INC EDI
	LOOP OnISBNValues
	
	MOV EAX, EBX
	MOV ECX, 11
	DIV ECX										;Divide summation to get remainder stored in EDX
	CMP EDX, 0
	JNE NotValid								;If remainder is not equal zero, the code is invalid
	
	MOV EAX, 1									;Mark that ISBN code is valid
	JMP Continue
	
	NotValid:
		MOV EAX, 0								;Mark that ISBN code is invalid
	Continue:
	RET

ValidateISBN ENDP

;-----------------------------------------------
;Calculates:	Displays the result of validation of the ISBN code
;Receives:		EAX contains 1 if the code is valid, and 0 if the code is invalid
;Returns:		Nothing
;-----------------------------------------------
DisplayResult PROC USES EDX EAX

	MOV EDX, OFFSET header
	CALL WriteString
	MOV EDX, OFFSET stringISBN
	CALL WriteString							;Display friendly message

	CMP EAX, 0
	JE NotValid

	MOV EDX, OFFSET validMessage
	JMP Continue

	NotValid:
		MOV EDX, OFFSET invalidMessage
	Continue:
		CALL WriteString
		CALL CRLF
	RET

DisplayResult ENDP


;-----------------------------------------------
;Calculates:	Removes the file structure garbage from the file then checks if the file came to an end
;Receives:		EAX contains the file handle,
;				EDX contains offset of string that will contain file structure garbage,
;				ECX contains length of the file structure garbage
;Returns:		EAX contains 0 if file is now empty or if the file handle is invalid
;-----------------------------------------------
CheckIfEOF PROC USES ECX EDX

	CALL ReadFromFile							;Collecting garbage from file
	JNC Valid

	Error:
		CALL WriteWindowsMsg					;Display error message
		MOV EAX, 0
	Valid:
	RET

CheckIfEOF ENDP

END main