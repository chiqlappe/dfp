
;-------------------------------
;BASIC�p�T�u���[�`��
;�����P�[�^�u��
;
;����
; �g�p���̓V���A���|�[�g�����L�̐ݒ�ɂ��邱��
;  PC-8001   :�����̃W�����p��1-5�ɂ���
;  PC-8001mk2:�w�ʂ̃W�����p�X�C�b�`��4�ɂ���
;
; �t�H���_����2���̐���
;  (��) "01"
; �t�@�C������3���̐���+".mp3"
;  (��) "001.mp3"
;
;�Q�l�����uKT403A �`�b�v�E�}�j���A���v
;   https://drive.google.com/file/d/1FfOZJdB9Q0GYQllW3_FLckE7aC8jizcE/view
;-------------------------------

DFP_CMD_MEDIA		equ	$09	;�Đ�����f�o�C�X��I������
DFP_CMD_RESET		equ	$0C	;�`�b�v�����Z�b�g����
DFP_USB			equ	1	;USB
DFP_SD			equ	2	;SD
DFP_SIZE		equ	10	;�R�}���h�o�C�g��̃T�C�Y
UARTD			equ	$20	;UART �f�[�^�|�[�g
UARTC			equ	UARTD+1	;UART �R���g���[���|�[�g
UART_TIMEOUT		equ	$1000	;�^�C���A�E�g����
TXRDY			equ	0	;���M���f�B�X�e�[�^�X�̃r�b�g�ԍ�
RXRDY			equ	1	;��M���f�B�X�e�[�^�X�̃r�b�g�ԍ�

SYS_LAST30H		equ	$EA66
SYS_PRINT		equ 	$52ED	;HL�ȍ~�Ɋi�[���ꂽ������(0�I�[)���o�͂���


	org	$E000			;�����P�[�^�u��

	JP	DFP.USR_RESET		;+00 ���������[�`���B�ŏ��Ɉ�x����USR�֐��ŃR�[������B�G���[�Ȃ�Ԃ�l=-1
	JP	DFP.USR_CMD		;+03 �R�}���h���M���[�`���B�R�}���h�ƃp�����[�^����������POKE���Ă���USR�֐��ŃR�[������B�G���[�Ȃ�Ԃ�l=-1


;-------------------------------
;DFPlayer mini �h���C�o
;-------------------------------
DFP:

	;���M�f�[�^
.DATA:	db	$7E,	; +0�o�C�g��=�J�n�R�[�h($7E)
	db	$FF,	; +1�o�C�g��=�o�[�W����($FF)
	db	$06,	; +2�o�C�g��=�f�[�^��($06)
.CMD:	db	$00,	; +3�o�C�g��=�R�}���h
	db	$00,	; +4�o�C�g��=�t�B�[�h�o�b�N�t���O($00=�Ȃ�)
.PARAM:	db	$00,	; +5�o�C�g��=�p�����[�^�̏��
	db	$00,	; +6�o�C�g��=�p�����[�^�̉���
.CSUM:	db	$00,	; +7�o�C�g��=�`�F�b�N�T���̏��
	db	$00,	; +8�o�C�g��=�`�F�b�N�T���̉���
	db	$EF	; +9�o�C�g��=�I���R�[�h($EF)

	;USR�֐��p
	;�|�[�g�ƃ`�b�v�̏�����
.USR_RESET:
	PUSH	HL			;�Ԃ�l�p��FAC+5��ޔ�

	LD	A,%01001101		;�{�[���[�g=x1,�L�����N�^��=8�r�b�g,�X�g�b�v�r�b�g=1�r�b�g
	CALL	UART.RESET		;�V���A���|�[�g������������

	LD	HL,$0000
	LD	(.PARAM),HL		;�p�����[�^
	LD	A,DFP_CMD_RESET		;�`�b�v�����Z�b�g����
	LD	(.CMD),A
	CALL	.SEND			;out:CY
	JR	NC,.GOOD
;;	JR	.ERROR

.ERROR:	LD	A,$FF			;�G���[�Ȃ�-1��Ԃ�l�Ƃ���
	JR	.EXIT

.GOOD:	LD	A,0			;����Ȃ�0��Ԃ�l�Ƃ���
.EXIT:	POP	HL			;=FAC+5
	LD	(HL),A			;�Ԃ�l���Z�b�g����
	INC	HL
	LD	(HL),A
	RET

	;USR�֐��p
	;�R�}���h���M
	; in:A=�����̌^,HL=FAC+5,(DFP.PARAM)=�p�����[�^���,(DFP.PARAM+1)=�p�����[�^����,(DFP.CMD)=�R�}���h�ԍ�
.USR_CMD:
	CP	2
	RET	NZ			;�����������^�łȂ���Ώ������Ȃ�

	PUSH	HL			;�Ԃ�l�p��FAC+5��ޔ�

	CALL	.SEND			;out:CY
	JR	NC,.GOOD
	JR	.ERROR

	; in:(DFP.PARAM)=�p�����[�^���,(DFP.PARAM+1)=�p�����[�^����,(DFP.CMD)=�R�}���h�ԍ�
	; out:CY=�G���[�t���O
.SEND:

	;�`�F�b�N�T�������߂�
	; +1�o�C�g�ڂ���6�o�C�g���Ώ�
	LD	DE,.DATA+1
	LD	HL,$0000
	LD	B,6			;�f�[�^��
.L1:	LD	A,(DE)
	INC	DE
	ADD	A,L			;HL+=A
	LD	L,A
	ADC	A,H
	SUB	L
	LD	H,A
	DJNZ	.L1
	EX	DE,HL
	LD	HL,$0000
	OR	A
	SBC	HL,DE			;HL=�`�F�b�N�T��
	LD	A,H
	LD	H,L
	LD	L,A
	LD	(.CSUM),HL		;�`�F�b�N�T�����f�[�^�ɃZ�b�g����

	LD	HL,.DATA
	LD	B,DFP_SIZE
	JR	UART.SEND		;out:CY


;-------------------------------
;UART8251 �h���C�o
;-------------------------------
UART:
	;�f�[�^���M
	; in:HL=���M�f�[�^�|�C���^,B=�o�C�g��
	; out:CY=�G���[�t���O
.SEND:	LD	C,UARTD			;�o�͐�̃|�[�g�A�h���X
.L2:	LD	DE,UART_TIMEOUT
.L1:	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,.L3
	SCF				;�^�C���A�E�g������������CY�𗧂ĂĖ߂�
	RET

.L3:	IN	A,(UARTC)		;���MREADY�ɂȂ�܂ő҂�
	AND	1<<TXRDY
	JR	Z,.L1
	OUTI				;�w�肳�ꂽ�o�C�g���̃f�[�^�𑗐M����
	JR	NZ,.L2
	OR	A			;���ׂẴf�[�^�𑗐M������CY���~�낵�Ė߂�
	RET

	;UART���Z�b�g
	; in:A=���[�h���[�h
.RESET:	PUSH	BC
	PUSH	AF			;���[�h���[�h��ޔ�
	XOR	A			;���Z�b�g�̑O�Ƀ_�~�[�f�[�^�𑗐M
	LD	C,UARTC
	OUT	(C),A
	OUT	(C),A
	OUT	(C),A
	LD	A,%01000000		;�������Z�b�g
	OUT	(C),A			;�R�}���h���s
	POP	AF			;���[�h���[�h�𕜋A
	OUT	(C),A			;���[�h�Z�b�g
	LD	A,%00110111		;���M�C�l�[�u��,DTR��LOW,��M�C�l�[�u��,�G���[�t���O�����Z�b�g,RTS��LOW
	OUT	(C),A			;�R�}���h���s

	LD	A,(SYS_LAST30H)		;8251�̐ڑ�����V���A���\�P�b�g�ɕύX����
	AND	%11001111
	OR	%00100000
	LD	(SYS_LAST30H),A
	OUT	($30),A

	POP	BC
	RET


