.model small
.stack 100h

.data
    idPrompt db 'Please enter your ID: $'
    partnerPrompt db 13, 10, 'Do you want to enter a partner ID (Y/N)? $'
    menuPrompt db 13, 10, '1. Show IDs', 13, 10, '2. Count', 13, 10, '3. Sum', 13, 10, '4. Mean', 13, 10, '5. Median', 13, 10, '6. Max', 13, 10, '7. Min', 13, 10, '8. Add ID', 13, 10, '9. Exit', 13, 10, 'Enter your choice: $'
    newLine db 13, 10, '$'
    countMsg db 'Number of IDs: $'
    sumMsg db 'The sum of all IDs: $'
    meanMsg db 'The mean: $'
    medianMsg db 'The median: $'
    maxMsg db 'The maximum number: $'
    minMsg db 'The minimum number: $'
    newIdPrompt db 'Enter a new ID: $'
    idBuffer db 100 dup(0) ; Buffer to store up to 100 characters
    idLength dw 0 ; Length of IDs entered
    idCount dw 0      
    numberStr db 6 dup(?), '$'
    maxValue dw 0
    minValue dw 0xFFFF ; Initialize to the maximum possible value

.code
main proc
    mov ax, @data
    mov ds, ax

getIds:
    lea dx, idPrompt ; Prompt for entering ID
    mov ah, 9h
    int 21h

    mov si, offset idBuffer
    add si, idLength ; Point SI to where the new ID should start

    mov cx, 7 ; Length of an ID

readId:
    mov ah, 1h ; Read a single character
    int 21h
    mov [si], al ; Store the character
    inc si

    loop readId ; Continue reading until the ID is complete

    add idLength, 7 ; Update total length
    inc word ptr [idCount] ; Increase count for each ID

    lea dx, partnerPrompt ; Prompt for partners in the team
    mov ah, 9h
    int 21h
    mov ah, 1h
    int 21h
    cmp al, 'Y'
    je newlineAndGetIds ; If yes, proceed to get another ID

menu:
    lea dx, menuPrompt ; Prompt for menu choice
    mov ah, 9h
    int 21h
    mov ah, 1h
    int 21h
    cmp al, '1'
    je showIds ; If choice is 1, show IDs
    cmp al, '2'
    je countIds ; If choice is 2, count IDs
    cmp al, '3'
    je sumIds ; If choice is 3, calculate sum
    cmp al, '4'
    je meanId ; If choice is 4, calculate mean
    cmp al, '5'
    je medianId ; If choice is 5, calculate median
    cmp al, '6'
    je maxId ; If choice is 6, find maximum
    cmp al, '7'
    je minId ; If choice is 7, find minimum
    cmp al, '8'
    je addId ; If choice is 8, add new ID
    cmp al, '9'
    je exitProgram ; If choice is 9, exit the program
    jmp menu ; If choice is invalid, show menu again

newlineAndGetIds:
    lea dx, newLine ; Print newline
    mov ah, 9h
    int 21h
    jmp getIds ; Get another ID

showIds:
    lea dx, newLine ; Print newline
    mov ah, 9h
    int 21h
    mov si, offset idBuffer
    mov cx, idLength
    mov bx, 7 ; Number of characters per ID

showIdsLoop:
    mov dl, [si] ; Get a character from ID
    mov ah, 2h ; Print character
    int 21h
    inc si
    dec bx
    jnz skipNewLine ; If BX != 0, skip printing a newline

    lea dx, newLine ; Print newline after each ID
    mov ah, 9h
    int 21h
    mov bx, 7 ; Reset BX for the next ID

skipNewLine:
    loop showIdsLoop ; Repeat until all IDs are shown

    jmp menu ; Return to menu

countIds: 
    lea dx, newLine ; Print newline
    mov ah, 9h
    int 21h
    lea dx, countMsg ; Print count message
    mov ah, 9h
    int 21h
    mov ax, [idCount] ; Load ID count
    call PrintNumber ; Print the count
    jmp menu ; Return to menu

sumIds: 
    lea dx, newLine ; Print newline
    mov ah, 9h
    int 21h
    lea dx, sumMsg ; Print sum message
    mov ah, 9h
    int 21h
    mov si, offset idBuffer
    mov cx, idLength
    xor ax, ax ; Clear AX for the sum

sumIdsLoop:
    mov bl, [si] ; Get a character from ID
    sub bl, '0' ; Convert from ASCII to integer
    add ax, bx ; Add to the sum
    inc si
    loop sumIdsLoop ; Repeat until sum is calculated

    call PrintNumber ; Print the sum
    jmp menu ; Return to menu

meanId: 
    lea dx, newLine ; Print newline
    mov ah, 9h
    int 21h
    lea dx, meanMsg ; Print mean message
    mov ah, 9h
    int 21h
    mov si, offset idBuffer
    xor ax, ax ; Clear AX for the sum
    xor bx, bx ; Clear BX as a counter for number of digits
    mov cx, idLength

meanIdLoop:
    mov bl, [si] ; Get a character from ID
    sub bl, '0' ; Convert from ASCII to integer
    add al, bl ; Add to the sum
    inc bx ; Increment digit counter
    inc si
    loop meanIdLoop ; Repeat until sum and digit count are calculated
    
    ; BX now contains total count of digits
    
    ; Add half of the divisor to the dividend for rounding
    mov dx, bx
    shr dx, 1 ; dx = bx / 2
    add ax, dx ; ax = ax + dx

    ; Divide the sum by the total number of digits to get the mean
    cwd ; Extend AX into DX:AX
    idiv bx

    call PrintNumber ; Print the mean
    jmp menu ; Return to menu

medianId: 
    lea dx, newLine ; Print newline
    mov ah, 9h
    int 21h
    lea dx, medianMsg ; Print median message
    mov ah, 9h
    int 21h

    mov si, offset idBuffer
    mov cx, idLength

    mov dx, cx ; Save the length of IDs
    shr dx, 1 ; Divide by 2 to get the middle position
    jnc medianEven ; If the length is even, jump to medianEven

    medianOdd:
    mov bx, dx ; BX = middle position
    jmp medianLoop ; Jump to the median calculation loop

    medianEven:
    dec cx ; Decrement length by 1
    mov bx, cx ; BX = length - 1 (0-based indexing)
    shr bx, 1 ; Divide by 2 to get the first middle position
    add bx, 2 ; Add 2 to skip the newline characters
    jmp medianLoop ; Jump to the median calculation loop

    medianLoop:
    mov si, offset idBuffer ; Start from the beginning of IDs

    medianLoopStart:
    cmp bx, 0 ; Check if BX reached 0
    je medianFound ; If yes, median found

    inc si ; Increment SI to the next character
    cmp byte ptr [si], 13 ; Check for newline character
    je medianLoopStart ; If newline, skip

    dec bx ; Decrement BX
    jmp medianLoopStart ; Repeat until median is found

    medianFound:
    mov dl, [si] ; Get the median character
    mov ah, 2h ; Print character
    int 21h

    jmp menu ; Return to menu

maxId:
    lea dx, newLine ; Print newline
    mov ah, 9h
    int 21h
    lea dx, maxMsg ; Print maximum message
    mov ah, 9h
    int 21h

    mov si, offset idBuffer
    mov cx, idLength

    mov ax, 0 ; Clear AX for the maximum value

maxIdLoop:
    mov bl, [si] ; Get a character from ID
    sub bl, '0' ; Convert from ASCII to integer
    cmp ax, bx ; Compare with current maximum value
    jge skipMaxUpdate ; If greater or equal, skip updating

    mov ax, bx ; Update the maximum value

skipMaxUpdate:
    inc si
    loop maxIdLoop ; Repeat until maximum value is found

    call PrintNumber ; Print the maximum value
    jmp menu ; Return to menu

minId:
    lea dx, newLine ; Print newline
    mov ah, 9h
    int 21h
    lea dx, minMsg ; Print minimum message
    mov ah, 9h
    int 21h

    mov si, offset idBuffer
    mov cx, idLength

    ; Load first character into AX as the initial minimum value
    mov bl, [si]
    sub bl, '0' ; Convert from ASCII to integer
    mov ax, bx

    ; Start loop from the second character
    inc si
    dec cx

minIdLoop:
    mov bl, [si] ; Get a character from ID
    sub bl, '0' ; Convert from ASCII to integer
    cmp ax, bx ; Compare with current minimum value
    jle skipMinUpdate ; If less or equal, skip updating

    mov ax, bx ; Update the minimum value

skipMinUpdate:
    inc si
    loop minIdLoop ; Repeat until minimum value is found

    call PrintNumber ; Print the minimum value
    jmp menu ; Return to menu

addId:
    lea dx, newLine ; Print newline
    mov ah, 9h
    int 21h
    lea dx, newIdPrompt ; Prompt for new ID
    mov ah, 9h
    int 21h

    mov si, offset idBuffer
    add si, idLength ; Point SI to where the new ID should start

    mov cx, 7 ; Length of an ID

readNewId:
    mov ah, 1h ; Read a single character
    int 21h
    mov [si], al ; Store the character
    inc si

    loop readNewId ; Continue reading until the new ID is complete

    add idLength, 7 ; Update total length
    inc word ptr [idCount] ; Increase count for each ID

    jmp menu ; Return to menu

exitProgram:
    mov ax, 4C00h ; Exit the program
    int 21h

main endp

PrintNumber:
    mov di, offset numberStr + 5 ; Start from the end of the string
    mov byte ptr [di], '$' ; Null-terminate the string

    mov bx, 10 ; We are converting to decimal (base 10)

convertLoop:
    xor dx, dx ; Clear DX for the division
    div bx ; AX = DX:AX / BX, DX = remainder
    add dl, '0' ; Convert the remainder to ASCII
    dec di ; Move to the previous character
    mov [di], dl ; Store the character
    test ax, ax ; Check if AX is not zero
    jnz convertLoop ; If it's not, continue the loop

printLoop:
    mov ah, 2 ; Function to write a character
    mov dl, [di] ; Get the character to print
    int 21h ; Call DOS
    inc di ; Move to the next character
    cmp byte ptr [di], '$' ; Check if we reached the end of the string
    jne printLoop ; If we didn't, continue the loop
        
    ret

end main
