;===============================================================================
;
; ROMDump.x version 1.25 by �݂� (miyu rose)
;
;  ROMDump.x ([options])
;   [options]
;    f : $F00000-$FFFFFF   X68KROM.DAT ���_���v���܂�
;    c : $F00000-$FBFFFF     CGROM.DAT ���_���v���܂�
;    3 : $FC0000-$FDFFFF     ROM30.DAT �����݂�����_���v���܂�
;    i : $FE0000-$FFFFFF    IPLROM.DAT ���_���v���܂�
;    n : $FC0000-$FC1FFF SCSIINROM.DAT �����݂�����_���v���܂�
;    x : $EA0020-$EA1FFF SCSIEXROM.DAT �����݂�����_���v���܂�
;    a : ��L�S�Ă��_���v���܂�
;
;  �ȉ��̃_���v�t�@�C�����쐬����v���O�����ł�
;   $F00000-$FFFFFF X68KROM.DAT
;   $F00000-$FBFFFF CGROM.DAT
;   $FC0000-$FDFFFF ROM30.DAT (���݂���ꍇ�̂�)
;   $FE0000-$FFFFFF IPLROM.DAT
;   $FC0000-$FC1FFF SCSIINROM.DAT (���݂���ꍇ�̂�)
;   $EA0020-$EA1FFF SCSIEXROM.DAT (���݂���ꍇ�̂�)
;
;===============================================================================

    .include  doscall.mac
    .cpu  68000

;-------------------------------------------------------------------------------
 
    .text
    .even

;===============================================================================

main:
    lea.l   mysp,sp

;===============================================================================

title:
    
    move.w  #$0006,d0                  ; $6 = $2(���F) + $4(����)
    lea.l   mes_title,a0               ; �^�C�g��
    bsr     cprint

    move.w  #$0007,d0                  ; $7 = $3(��)   + $4(����)
    lea.l   mes_version,a0             ; �o�[�W����
    bsr     cprint

    move.w  #$0003,d0                  ; $3(��)
    lea.l   mes_by,a0                  ; by
    bsr     cprint

    move.w  #$0007,d0                  ; $7 = $3(��)   + $4(����)
    lea.l   mes_author,a0              ; ���
    bsr     cprint

    move.w  #$0003,d0                  ; $3(��)
    lea.l   mes_nul,a0
    bsr     cprint

;===============================================================================

arg_check:                             ; �R�}���h���C�������̃`�F�b�N
    addq.l  #1,a2                      ; �����̃T�C�Y�͖���

arg_loop:                              ; �R�}���h���C�������������[�`��
    move.b  (a2)+,d0                   ; �������P�����t�F�b�`
    cmpi.b  #' ',d0                    ; �X�y�[�X���ȁH
    beq     arg_loop                   ; �X�y�[�X �Ȃ� �X�L�b�v
    ori.b   #$20,d0                    ; �p����������
    cmpi.b  #'c',d0                    ; 'c' ���ȁH
    beq     option_CGROM               ; 'c' �Ȃ� CGROM.DAT �w��
    cmpi.b  #'3',d0                    ; '3' ���ȁH
    beq     option_ROM30               ; '3' �Ȃ� ROM30.DAT �w��
    cmpi.b  #'i',d0                    ; 'i' ���ȁH
    beq     option_IPLROM              ; 'i' �Ȃ� IPLROM.DAT �w��
    cmpi.b  #'n',d0                    ; 'n' ���ȁH
    beq     option_SCSIINROM           ; 'n' �Ȃ� SCSIINROM.DAT �w��
    cmpi.b  #'x',d0                    ; 'x' ���ȁH
    beq     option_SCSIEXROM           ; 'x' �Ȃ� SCSIEXROM.DAT �w��
    cmpi.b  #'f',d0                    ; 'f' ���ȁH
    beq     option_X68KROM             ; 'f' �Ȃ� X68KROM.DAT �w��
    cmpi.b  #'a',d0                    ; 'a' ���ȁH
    beq     option_all                 ; 'a' �Ȃ� �SROM �w��

    bra     option_check               ; �����`�F�b�N��

option_CGROM:
    ori.b   #$01, flg_option           ; CGROM �w��I�v�V�����𗧂Ă�
    bra     arg_loop                   ; ���������֖߂�

option_ROM30:
    ori.b   #$02, flg_option           ; ROM30 �w��I�v�V�����𗧂Ă�
    bra     arg_loop                   ; ���������֖߂�

option_IPLROM:
    ori.b   #$04, flg_option           ; IPLROM �w��I�v�V�����𗧂Ă�
    bra     arg_loop                   ; ���������֖߂�

option_SCSIINROM:
    ori.b   #$10, flg_option           ; SCSIINROM �w��I�v�V�����𗧂Ă�
    bra     arg_loop                   ; ���������֖߂�

option_SCSIEXROM:
    ori.b   #$20, flg_option           ; SCSIEXROM �w��I�v�V�����𗧂Ă�
    bra     arg_loop                   ; ���������֖߂�

option_X68KROM:
    ori.b   #$80, flg_option           ; X68KROM �w��I�v�V�����𗧂Ă�
    bra     arg_loop                   ; ���������֖߂�

option_all:                            ; �SROM �w��I�v�V�����𗧂Ă�
    ori.b   #$B7, flg_option
    bra     arg_loop                   ; ���������֖߂�

option_check:
    tst.b   flg_option                 ; �����w��m�F
    bne     arg_end                    ; �w�肳��Ă��烁�C�����[�`����

;-------------------------------------------------------------------------------

help:
    pea.l   mes_help                   ; �w���v���b�Z�[�W
    DOS     _PRINT                     ; �\��
    addq.l  #4,sp

    DOS     _EXIT                      ; �I��


arg_end:

;===============================================================================

SUPERVISORMODE:
    clr.l   -(sp)                      ; �X�[�p�[�o�C�U�[���[�h
    DOS     _SUPER
    or.l    d0,d0                      ; ���� SSP �A�h���X��
    bpl     @f                         ; �������擾�ł����琬���Ȃ̂Ŏ���

;-------------------------------------------------------------------------------

    pea.l   mes_error                  ; �\�����ʓ�G���[
    DOS     _PRINT                     ; �\��
    addq.l  #4,sp

    DOS     _EXIT                      ; �I��

@@:

;-------------------------------------------------------------------------------

    move.l  d0, (sp)                   ; SUPER VISOR ���[�h�ɂȂꂽ�̂� SSP �ۑ�

;===============================================================================

X68KROM:
    btst.b  #7, flg_option             ; X68KROM �w��I�v�V�������m�F
    beq     @f                         ; �w�肳��ĂȂ���Ύ���

    move.l  #$F00000,d0                ; X68KROM �̐擪�A�h���X
    move.l  #$100000,d1                ; X68KROM �̃T�C�Y
    move.l  #filename_X68KROM,d2       ; X68KROM �̃t�@�C����
    bsr     dump                       ; �_���v

@@:

;-------------------------------------------------------------------------------

CGROM:
    btst.b  #0, flg_option             ; CGROM �w��v�V�������m�F
    beq     @f                         ; �w�肳��ĂȂ���Ύ���

    move.l  #$F00000,d0                ; CGROM �̐擪�A�h���X
    move.l  #$0C0000,d1                ; CGROM �̃T�C�Y
    move.l  #filename_CGROM,d2         ; X68KROM �̃t�@�C����
    bsr     dump                       ; �_���v

@@:

;-------------------------------------------------------------------------------

IPLROM:
    btst.b  #2, flg_option             ; IPLROM �w��I�v�V�������m�F
    beq     @f                         ; �w�肳��ĂȂ���Ύ���

    move.l  #$FE0000,d0                ; IPLROM �̐擪�A�h���X
    move.l  #$020000,d1                ; IPLROM �̃T�C�Y
    move.l  #filename_IPLROM,d2        ; IPLROM �̃t�@�C����
    bsr     dump                       ; �_���v

@@:

;-------------------------------------------------------------------------------

ROM30:
    btst.b  #1, flg_option             ; ROM30 �w��I�v�V�������m�F
    beq     @f                         ; �w�肳��ĂȂ���Ύ���

    movea.l #$00FC023C,a0              ; IPLROM 1.5 �� ROM30 Human �`�F�b�N
    cmpi.l  #'uman',(a0)
    beq     ROM30_dump

    movea.l #$00FC203C,a0              ; IPLROM 1.6 �� ROM30 Human �`�F�b�N
    cmpi.l  #'uman',(a0)
    beq     ROM30_dump                 ; ROM30 Human ���݂������̂Ń_���v

    pea.l   filename_ROM30             ; �t�@�C���� 
    DOS     _PRINT                     ; �\��
    addq.l  #4,sp
    pea.l   mes_santen                 ; �O�_���[�_�[
    DOS     _PRINT                     ; �\��
    addq.l  #4,sp
    pea.l   mes_dontexist              ; ���݂��܂���ł���
    DOS     _PRINT                     ; �\��
    addq.l  #4,sp

    bra     @f                         ; ����

ROM30_dump:
    move.l  #$FC0000,d0                ; ROM30 �̐擪�A�h���X
    move.l  #$020000,d1                ; ROM30 �̃T�C�Y
    move.l  #filename_ROM30,d2         ; ROM30 �̃t�@�C����
    bsr     dump                       ; �_���v
;   bra     @@f

@@:

;-------------------------------------------------------------------------------

SCSIINROM:
    btst.b  #4, flg_option             ; SCSIINROM �w��I�v�V�������m�F
    beq     @f                         ; �w�肳��ĂȂ���Ύ���

    movea.l #$00FC0024,a0              ; SCSIINROM ���݃`�F�b�N
    cmpi.l  #'SCSI',(a0)
    beq     SCSIINROM_dump             ; SCSIINROM �����݂���΃_���v

    pea.l   filename_SCSIINROM         ; �t�@�C����
    DOS     _PRINT                     ; �\��
    addq.l  #4,sp
    pea.l   mes_santen                 ; �O�_���[�_�[
    DOS     _PRINT                     ; �\��
    addq.l  #4,sp
    pea.l   mes_dontexist              ; ���݂��܂���ł���
    DOS     _PRINT                     ; �\��
    addq.l  #4,sp

    bra     @f                         ; ����

SCSIINROM_dump
    move.l  #$FC0000,d0                ; SCSIINROM �̐擪�A�h���X
    move.l  #$002000,d1                ; SCSIINROM �̃T�C�Y
    move.l  #filename_SCSIINROM,d2     ; SCSIINROM �̃t�@�C����
    bsr     dump                       ; �_���v

@@:

;-------------------------------------------------------------------------------

SCSIEXROM:
    btst.b  #5, flg_option             ; SCSIEXROM �w��I�v�V�������m�F
    beq     @f                         ; �w�肳��ĂȂ���Ύ���

BUSERROR_hook:
    move.l  sp,a2                      ; sp��ޔ�
    move.l  $0008.w,a1                 ; �o�X�G���[�̃x�N�^��ޔ�
    lea.l   BUSERROR_resume(pc),a0     ; �x�N�^�̕ύX��A�h���X
    move.l  a0,$0008.w                 ; �o�X�G���[�̃x�N�^����������

    moveq.l #0, d2                     ; �t�@�C�����A�h���X�i�[�p�� d2 ���W�X�^��������
    movea.l #$00EA0044,a0
    cmpi.l  #'SCSI',(a0)               ; SCSI�{�[�h���������Ă��Ȃ��ꍇ�̓o�X�G���[�ŃX�L�b�v
    bne     BUSERROR_resume            ; SCSIEXROM ��F���ł��Ȃ��ꍇ���X�L�b�v

    move.l  #$00EA0020,d0              ; SCSIEXROM �̐擪�A�h���X
    move.l  #$001FE0,d1                ; SCSIEXROM �̃T�C�Y
    move.l  #filename_SCSIEXROM,d2     ; SCSIEXROM �̃t�@�C����
    bsr     dump                       ; �_���v

BUSERROR_resume:
    move.l  a2,sp                      ; sp�𕜌�
    move.l  a1,$0008.w                 ; �o�X�G���[�̃x�N�^�𕜌�

    tst.l   d2                         ; �t�@�C�����͎w�肳��Ă��邩�ȁH��SCSIEXROM�͑��݂��Ă����ȁH
    bne     @f                         ; SCSIEXROM �����݂��Ă����̂Ŏ���

    pea.l   filename_SCSIEXROM         ; �t�@�C���� 
    DOS     _PRINT                     ; �\��
    addq.l  #4,sp
    pea.l   mes_santen                 ; �O�_���[�_�[
    DOS     _PRINT                     ; �\��
    addq.l  #4,sp
    pea.l   mes_dontexist              ; ���݂��܂���ł���
    DOS     _PRINT                     ; �\��
    addq.l  #4,sp

@@:

;===============================================================================

USERMODE:
    DOS     _SUPER                     ; ���[�U�[���[�h��
    addq.l  #4,sp

complete:
    pea.l   mes_crlf                   ; ���s�R�[�h
    DOS     _PRINT                     ; �\��
    addq.l  #4,sp

    DOS     _EXIT                      ; �I��

;===============================================================================

cprint:
    move.w  d0,-(sp)
    move.w  #$0002,-(sp)
    DOS     _CONCTRL
    addq.l  #4,sp

    pea.l   (a0)
    DOS     _PRINT
    addq.l  #4,sp

    rts

;===============================================================================

dump:
    move.l  d1,-(sp)                   ; �J�n�A�h���X
    move.l  d0,-(sp)                   ; �T�C�Y
    clr.w   -(sp)                      ; �t�@�C������(�쐬��̓t�@�C���n���h��)
    move.l  d2,-(sp)                   ; �t�@�C����
    DOS     _PRINT
    pea.l   mes_santen                 ; �O�_���[�_�[
    DOS     _PRINT                     ; �\��
    addq.l  #4,sp
    DOS     _CREATE
    or.l    d0,d0                      ; �t�@�C���n���h����
    bmi     dump_failure               ; ���Ȃ�쐬���s

dump_success:
    addq.l  #4,sp
    move.w  d0,(sp)                    ; �t�@�C���n���h��(_CREATE �̕Ԃ�l)
    DOS     _WRITE                     ; ��������
    DOS     _CLOSE
    pea.l   mes_create                 ; �t�@�C���쐬�������b�Z�[�W
    DOS     _PRINT                     ; �\��
    lea.l   14(sp),sp
    moveq.l #0, d0                     ; �������̕Ԃ�l d0 : 0
    rts

dump_failure:                          ; �쐬���s
    pea.l   mes_cantcreate             ; �t�@�C���쐬���s���b�Z�[�W
    DOS     _PRINT                     ; �\��
    lea.l   18(sp),sp
    moveq.l #-1,d0                     ; ���s���̕Ԃ�l d0 : -1
    rts
;===============================================================================

    .data
    .even

;===============================================================================

flg_option:
    .dc.b   $00

;===============================================================================

    .data
    .even

;===============================================================================

filename_X68KROM:
    .dc.b   'X68KROM.DAT',$00
filename_CGROM:
    .dc.b   'CGROM.DAT',$00
filename_IPLROM:
    .dc.b   'IPLROM.DAT',$00
filename_ROM30:
    .dc.b   'ROM30.DAT',$00
filename_SCSIINROM:
    .dc.b   'SCSIINROM.DAT',$00
filename_SCSIEXROM:
    .dc.b   'SCSIEXROM.DAT',$00
mes_santen:
    .dc.b   ' �c ',$00
mes_create:
    .dc.b   '�쐬�����ł��R(=�L��`=)�',$0D,$0A,$00
mes_cantcreate:
    .dc.b   '�쐬�ł��܂���ł���(T�tT)',$0D,$0A,$00
mes_dontexist:
    .dc.b   '���݂��܂���ł���(T�tT)',$0D,$0A,$00
mes_error:
    .dc.b   '�ċN�����Ă�����߂Ă��������������܂��I',$0D,$0A,$0D,$0A,$00
mes_title:
    .dc.b   'ROMDump ',$00
mes_version:
    .dc.b   $F3,'v',$F3,'e',$F3,'r',$F3,'s',$F3,'i',$F3,'o',$F3,'n',$F3,' ',$F3,'1',$F3,'.',$F3,'2',$F3,'5',$00
mes_by:
    .dc.b   ' ',$F3,'b',$F3,'y ',$00
mes_author:
    .dc.b   '�݂� (miyu rose)',$0D,$0A,$0D,$0A,$00
mes_help:
    .dc.b   ' ROMDump.x ([options])',$0D,$0A
    .dc.b   '  [options]:',$0D,$0A
    .dc.b   '   f : $F00000-$FFFFFF   X68KROM.DAT ���_���v���܂�',$0D,$0A
    .dc.b   '   c : $F00000-$FBFFFF     CGROM.DAT ���_���v���܂�',$0D,$0A
    .dc.b   '   3 : $FC0000-$FDFFFF     ROM30.DAT �����݂�����_���v���܂�',$0D,$0A
    .dc.b   '   i : $FE0000-$FFFFFF    IPLROM.DAT ���_���v���܂�',$0D,$0A
    .dc.b   '   n : $FC0000-$FC1FFF SCSIINROM.DAT �����݂�����_���v���܂�',$0D,$0A
    .dc.b   '   x : $EA0020-$EA1FFF SCSIEXROM.DAT �����݂�����_���v���܂�',$0D,$0A
    .dc.b   '   a : ��L�S�Ă��_���v���܂�',$0D,$0A
mes_crlf:
    .dc.b   $0D,$0A
mes_nul:
    .dc.b   $00

;===============================================================================

    .stack
    .even

;===============================================================================

mystack:
    .ds.l   1024
mysp:
    .end    main

;===============================================================================
