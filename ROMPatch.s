;===============================================================================
;
; ROMPatch.x version 1.24 by みゆ (miyu rose)
;
;  ROMPatch.x ([options]) [filename] ([modelname])
;   [options]
;    -d|u           : モデル名|機種ｺｰﾄﾞ の情報を削除します
;    -0|3           : 機種ｺｰﾄﾞ を 初代|X68030 にします
;    -A|E|P         : 機種ｺｰﾄﾞ を ACE|EXPERT|PRO にします
;    -S|X|C         : 機種ｺｰﾄﾞ を SUPER|XVI|Compact にします
;    -I|II          : 機種ｺｰﾄﾞ に I|II を付加します
;    -HD|N          : 機種ｺｰﾄﾞ に HD を付加|除去します
;    -O|G|B|T       : 機種ｺｰﾄﾞ の色を ｵﾌｨｽｸﾞﾚｰ|ｸﾞﾚｰ|ﾌﾞﾗｯｸ|ﾁﾀﾝﾌﾞﾗｯｸ にします
;    -eR|eJ|eG|eM|eZ: ｴﾐｭﾚｰﾀｺｰﾄﾞ を 実機|XEiJ|XM6 TypeG|MiSTer|Z にします
;    -eN            : ｴﾐｭﾚｰﾀｺｰﾄﾞ を 設定なし にします
;    -1M|2M|4M|12M  : 指定の標準メモリ/STD起動にします (for XEiJ IPLROM)
;    -x             : 起動ロゴを X680x0 にします (for XEiJ IPLROM)
;    -h|?           : ヘルプを表示します
;   [filename]
;    パッチをあてる IPLROM ($fe0000-$ffffff) または
;    X68KROM ($f00000-$ffffff) のダンプファイルです
;   [modelname]
;    指定のモデル名(X68000 PhantomX 等)にリネームします
;    指定しない場合は現在設定中のモデル名を表示します
;
;
;  [ｴﾐｭﾚｰﾀｺｰﾄﾞ(仮)] $00FFFFFE
;  実機            = $00
;  XEiJ            = $01
;  XM6 TypeG       = $02
;  X68000_MiSTer   = $03
;  X68000 Z        = $0f
;  設定無し        = $FF
;  ※これらの値は仮です。将来変更となる可能性があります
;
;  [機種ｺｰﾄﾞ] $00FFFFFF
;  X68000          = 0b00000000;
;  X68030          = 0b10000000;
;  設定無し        = 0b11111111;
;
;  ACE             = 0b00010000;
;  EXPERT          = 0b00100000;
;  PRO             = 0b00110000;
;  SUPER           = 0b01000000;
;  XVI             = 0b01010000;
;  COMPACT         = 0b01100000;
;
;  II              = 0b00001000;
;  HD              = 0b00000100;
;
;  OFFICE_GRAY     = 0b00000000;
;  GRAY            = 0b00000001;
;  TITAN_BLACK     = 0b00000010;
;  BLACK           = 0b00000011;
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
    move.w  #$0006,d0                  ; $6 = $2(黄色) + $4(太字)
    lea.l   mes_title,a0               ; タイトル
    bsr     cprint

    move.w  #$0007,d0                  ; $7 = $3(白)   + $4(太字)
    lea.l   mes_version,a0             ; バージョン
    bsr     cprint

    move.w  #$0003,d0                  ; $3(白)
    lea.l   mes_by,a0                  ; by
    bsr     cprint

    move.w  #$0007,d0                  ; $7 = $3(白)   + $4(太字)
    lea.l   mes_author,a0              ; 作者
    bsr     cprint

    move.w  #$0003,d0                  ; $3(白)
    lea.l   mes_nul,a0
    bsr     cprint

;===============================================================================

arg_check:                             ; コマンドライン引数のチェック
    addq.l  #1,a2                      ; 引数のサイズは無視

arg_skip:
    move.b  (a2)+,d0
    cmpi.b  #$00,d0                    ; 引数終端かな？
    beq     arg_end                    ; 終端なので終了
    cmpi.b  #' ',d0
    beq     arg_skip                   ; スペースはスキップ
    cmpi.b  #'-',d0                    ; '-' かな？
    beq     arg_option                 ; '-' はオプション文字のプレフィクス
    cmpi.b  #'/',d0                    ; '/' かな？
    bne     arg_filename               ; '/' だったらオプション文字のプレフィクスだけど
                                       ; そうじゃないのできっとファイルネーム
arg_option:
    move.b  (a2)+,d0
    cmpi.b  #$00,d0                    ; 引数終端かな？
    beq     help                       ; 書式おかしいのでヘルプ表示
    cmpi.b  #'h',d0
    beq     help                       ; -h や /h はヘルプ表示
    cmpi.b  #'?',d0
    beq     help                       ; -? や /? はヘルプ表示
    cmpi.b  #'d',d0
    beq     arg_flag_delete_name       ; -d や /D は モデル名情報削除
    cmpi.b  #'u',d0
    beq     arg_flag_unset_modelcode   ; -u や /U は 機種ｺｰﾄﾞ情報削除
    cmpi.b  #'0',d0
    beq     arg_flag_X68000            ; -0 や /0 は X68000 フラグ
    cmpi.b  #'3',d0
    beq     arg_flag_X68030            ; -3 や /3 は X68030 フラグ
    cmpi.b  #'A',d0
    beq     arg_flag_ACE               ; -A や /A は ACE フラグ
    cmpi.b  #'E',d0
    beq     arg_flag_EXPERT            ; -E や /E は EXPERT フラグ
    cmpi.b  #'P',d0
    beq     arg_flag_PRO               ; -P や /P は PRO フラグ
    cmpi.b  #'S',d0
    beq     arg_flag_SUPER             ; -S や /S は SUPER フラグ
    cmpi.b  #'X',d0
    beq     arg_flag_XVI               ; -X や /X は XVI フラグ
    cmpi.b  #'C',d0
    beq     arg_flag_Compact           ; -C や /C は Compact フラグ
    cmpi.b  #'I',d0
    beq     arg_flag_I                 ; -I や /I は I または II フラグ
    cmpi.b  #'H',d0
    beq     arg_flag_H                 ; -H や /H は HD フラグ候補
    cmpi.b  #'N',d0
    beq     set_flag_N                 ; -N や /N は HD フラグ除去
    cmpi.b  #'O',d0
    beq     arg_flag_OfficeGray        ; -O や /O は OfficeGray フラグ
    cmpi.b  #'G',d0
    beq     arg_flag_Gray              ; -G や /G は Gray フラグ
    cmpi.b  #'T',d0
    beq     arg_flag_TitanBlack        ; -T や /T は TitanBlack フラグ
    cmpi.b  #'B',d0
    beq     arg_flag_Black             ; -B や /B は Black フラグ
    cmpi.b  #'e',d0
    beq     arg_flag_emulatorcode      ; -e や /e は エミュレータコード
    cmpi.b  #'1',d0
    beq     arg_flag_bootpatch1        ; -1 や /1 は 起動パッチ(1MB/STD)
    cmpi.b  #'2',d0
    beq     arg_flag_bootpatch2        ; -2 や /2 は 起動パッチ(2MB/STD)
    cmpi.b  #'4',d0
    beq     arg_flag_bootpatch4        ; -4 や /4 は 起動パッチ(4MB/STD)
    cmpi.b  #'x',d0
    beq     arg_flag_logopatch         ; -x や /x は ロゴパッチ
    cmpi.b  #' ',d0                    ; スペースかな？
    beq     arg_skip                   ; スペースならスキップして次の引数へ
    bra     arg_option                 ; 次のオプション文字へ (-bl など続けて書かれても対応)

;-------------------------------------------------------------------------------

arg_flag_bootpatch1:                   ; 1MB/STD起動
    move.b  (a2),d0                    ; 続く引数を取得
    cmpi.b  #'M',d0                    ; 前の文字とあわせて '1M' かな？
    beq     @f                         ; '1M' だったので次へ

    cmpi.b  #'2',d0                    ; 前の文字とあわせて '12' かな？
    bne     help                       ; '12' じゃなかったのでヘルプ表示

    addq.l  #1,a2                      ; '12' だったので引数を一文字すすめる
    move.b  (a2),d0                    ; 続く引数を取得
    cmpi.b  #'M',d0                    ; 前の文字とあわせて '12M' かな？
    bne     help                       ; '12M' じゃなかったのでヘルプ表示
    
    addq.l  #1,a2                      ; '12M' だったので引数を一文字すすめる
set_flag_bootpatch12:
    move.b  #1,flag_bootpatch          ; bootpatch フラグを立てる
    lea.l   bootpatch_00,a0
    move.l  #$00C00000,(a0)            ; 書き込むデータを 12MB にする
    lea.l   mes_bootpatched,a0
    move.b  #'1',(a0)+                 ; 表示メッセージを
    move.b  #'2',(a0)+                 ;  12MB
    move.b  #'M',(a0)                  ;   にする

    bra     arg_option                 ; 次のオプション文字へ

@@:
    addq.l  #1,a2                      ; '1M' だったので引数を一文字すすめる
set_flag_bootpatch1:
    move.b  #1,flag_bootpatch          ; bootpatch フラグを立てる
    lea.l   bootpatch_00,a0
    move.l  #$00100000,(a0)            ; 書き込むデータを 1MB にする
    lea.l   mes_bootpatched,a0
    move.b  #'1',(a0)+                 ; 表示メッセージを
    move.b  #'M',(a0)+                 ;  1MB
    move.b  #'B',(a0)                  ;   にする

    bra     arg_option                 ; 次のオプション文字へ

arg_flag_bootpatch2:                   ; 2MB/STD起動
    move.b  (a2),d0                    ; 続く引数を取得
    cmpi.b  #'M',d0                    ; 前の文字とあわせて '2M' かな？
    bne     help                       ; '2M' じゃなかったのでヘルプ表示
    addq.l  #1,a2                      ; '2M' だったので引数を一文字すすめる
set_flag_bootpatch2:
    move.b  #2,flag_bootpatch          ; bootpatch フラグを立てる
    lea.l   bootpatch_00,a0
    move.l  #$00200000,(a0)            ; 書き込むデータを 2MB にする
    lea.l   mes_bootpatched,a0
    move.b  #'2',(a0)+                 ; 表示メッセージを
    move.b  #'M',(a0)+                 ;  2MB
    move.b  #'B',(a0)                  ;   にする

    bra     arg_option                 ; 次のオプション文字へ

arg_flag_bootpatch4:                   ; 4MB/STD起動
    move.b  (a2),d0                    ; 続く引数を取得
    cmpi.b  #'M',d0                    ; 前の文字とあわせて '4M' かな？
    bne     help                       ; '4M' じゃなかったのでヘルプ表示
    addq.l  #1,a2                      ; '4M' だったので引数を一文字すすめる
set_flag_bootpatch4:
    move.b  #4,flag_bootpatch          ; bootpatch フラグを立てる
    lea.l   bootpatch_00,a0
    move.l  #$00400000,(a0)            ; 書き込むデータを 4MB にする
    lea.l   mes_bootpatched,a0
    move.b  #'4',(a0)+                 ; 表示メッセージを
    move.b  #'M',(a0)+                 ;  4MB
    move.b  #'B',(a0)                  ;   にする

    bra     arg_option                 ; 次のオプション文字へ

;-------------------------------------------------------------------------------

arg_flag_logopatch:
    move.b  #1,flag_logopatch          ; logopatch フラグを立てる
    bra     arg_option                 ; 次のオプション文字へ

;-------------------------------------------------------------------------------

arg_flag_delete_name:
    move.l  #$ffffffff,modelnametag    ; modelnametag を消す
    bra     arg_option                 ; 次のオプション文字へ

;-------------------------------------------------------------------------------

arg_flag_unset_modelcode:
    clr.b   mask_modelcode
    move.b  #$ff,flag_modelcode        ; 機種ｺｰﾄﾞ情報を削除
    bra     arg_option

;-------------------------------------------------------------------------------

arg_flag_X68000:
    andi.b  #$03,mask_modelcode
    andi.b  #$03,flag_modelcode        ; 初代 フラグ
    bra     set_flag_bootpatch1        ; 1MB/STD機動へ

;-------------------------------------------------------------------------------

arg_flag_ACE:
    andi.b  #$03,mask_modelcode
    andi.b  #$03,flag_modelcode
    ori.b   #$10,flag_modelcode        ; ACE フラグ
    bra     set_flag_bootpatch1        ; 1MB/STD機動へ

;-------------------------------------------------------------------------------

arg_flag_EXPERT:
    andi.b  #$03,mask_modelcode
    andi.b  #$03,flag_modelcode
    ori.b   #$20,flag_modelcode        ; EXPERT フラグ
    bra     set_flag_bootpatch1        ; 1MB/STD機動へ

;-------------------------------------------------------------------------------

arg_flag_PRO:
    andi.b  #$03,mask_modelcode
    andi.b  #$03,flag_modelcode
    ori.b   #$30,flag_modelcode        ; PRO フラグ
    bra     set_flag_bootpatch1        ; 1MB/STD機動へ

;-------------------------------------------------------------------------------

arg_flag_I:
    andi.b  #$f7,mask_modelcode        ; 
    andi.b  #$f7,flag_modelcode        ; I フラグ
    move.b  (a2),d0                    ; 続く引数を取得
    cmpi.b  #'I',d0                    ; 前の文字とあわせて 'II' かな？
    bne     arg_option                 ; 'II' じゃなかったので次のオプション文字へ
    addq.l  #1,a2                      ; 'II' だったので引数を一文字すすめる
arg_flag_II:
    ori.b   #$08,flag_modelcode        ; II フラグ
    bra     arg_option                 ; 次のオプション文字へ

;-------------------------------------------------------------------------------

arg_flag_SUPER:
    clr.b   mask_modelcode
    clr.b   flag_modelcode
    ori.b   #$42,flag_modelcode        ; SUPER フラグ
    bra     set_flag_bootpatch2        ; 2MB/STD機動へ

;-------------------------------------------------------------------------------

arg_flag_XVI:
    clr.b   mask_modelcode
    clr.b   flag_modelcode
    ori.b   #$52,flag_modelcode        ; XVI フラグ
    bra     set_flag_bootpatch2        ; 2MB/STD機動へ

;-------------------------------------------------------------------------------

arg_flag_Compact:
    andi.b  #$80,mask_modelcode
    andi.b  #$80,flag_modelcode
    ori.b   #$62,flag_modelcode        ; Compact (ｸﾞﾚｰ) フラグ
    move.b  flag_modelcode,d0
    andi.b  #$80,d0                    ; X68030 フラグを抽出
    beq     set_flag_bootpatch2        ; X68000 Compact なので 2MB/STD機動へ
    ori.b   #$63,flag_modelcode        ; Compact (ﾁﾀﾝﾌﾞﾗｯｸ) フラグ
    bra     set_flag_bootpatch4        ; X68030 Compact なので 4MB/STD機動へ

;-------------------------------------------------------------------------------

arg_flag_X68030:
    andi.b #$73,mask_modelcode
    ori.b  #$80,flag_modelcode
    bra     set_flag_bootpatch4        ; 4MB/STD機動へ

;-------------------------------------------------------------------------------

arg_flag_H:
    move.b  (a2),d0                    ; 続く引数を取得
    cmpi.b  #'D',d0                    ; 前の文字とあわせて 'HD' かな？
    bne     help                       ; 'HD' じゃなかったのでヘルプ表示
    addq.l  #1,a2                      ; 'HD' だったので引数を一文字すすめる
set_flag_HD:
    andi.b  #$fb,mask_modelcode
    ori.b   #$04,flag_modelcode        ; HD フラグ
    bra     arg_option                 ; 次のオプション文字へ
set_flag_N:
    andi.b  #$fb,mask_modelcode
    andi.b  #$fb,flag_modelcode        ; HD フラグを除去
    bra     arg_option                 ; 次のオプション文字へ

;-------------------------------------------------------------------------------

arg_flag_OfficeGray:
    andi.b  #$fc,mask_modelcode
    andi.b  #$fc,flag_modelcode        ; ｵﾌｨｽｸﾞﾚｰ に
    bra     arg_option                 ; 次のオプション文字へ
arg_flag_Gray:
    andi.b  #$fc,mask_modelcode
    andi.b  #$fc,flag_modelcode        ; 一旦 ｵﾌｨｽｸﾞﾚｰ に初期化
    ori.b   #$01,flag_modelcode        ; ｸﾞﾚｰ に
    bra     arg_option                 ; 次のオプション文字へ
arg_flag_Black:
    andi.b  #$fc,mask_modelcode
    ori.b   #$03,flag_modelcode        ; ﾌﾞﾗｯｸ に
    bra     arg_option                 ; 次のオプション文字へ
arg_flag_TitanBlack:
    andi.b  #$fc,mask_modelcode
    andi.b  #$fc,modelcode             ; 一旦 ｵﾌｨｽｸﾞﾚｰ に初期化
    ori.b   #$02,modelcode             ; ﾁﾀﾝﾌﾞﾗｯｸ に
    bra     arg_option                 ; 次のオプション文字へ

;-------------------------------------------------------------------------------
arg_flag_emulatorcode:
    move.b  (a2),d0                    ; 続く引数を取得
    cmpi.b  #'R',d0                    ; 前の文字とあわせて 'eR' かな？
    bne     @f                         ; 'eR' じゃなかったので次へ

    addq.l  #1,a2                      ; 'eR' だったので引数を一文字すすめる
    move.b  #$00, flag_emulatorcode    ; ｴﾐｭﾚｰﾀｺｰﾄﾞを 実機 に
    bra     arg_option                 ; 次のオプション文字へ

@@:
    cmpi.b  #'J',d0                    ; 前の文字とあわせて 'eJ' かな？
    bne     @f                         ; 'eJ' じゃなかったので次へ

    addq.l  #1,a2                      ; 'eJ' だったので引数を一文字すすめる
    move.b  #$01, flag_emulatorcode    ; ｴﾐｭﾚｰﾀｺｰﾄﾞを XEiJ に
    bra     arg_option                 ; 次のオプション文字へ

@@:
    cmpi.b  #'G',d0                    ; 前の文字とあわせて 'eG' かな？
    bne     @f                         ; 'eG' じゃなかったので次へ

    addq.l  #1,a2                      ; 'eG' だったので引数を一文字すすめる
    move.b  #$01, flag_emulatorcode    ; ｴﾐｭﾚｰﾀｺｰﾄﾞを XM6 TypeG に
    bra     arg_option                 ; 次のオプション文字へ

@@:
    cmpi.b  #'G',d0                    ; 前の文字とあわせて 'eG' かな？
    bne     @f                         ; 'eG' じゃなかったので次へ

    addq.l  #1,a2                      ; 'eG' だったので引数を一文字すすめる
    move.b  #$02, flag_emulatorcode    ; ｴﾐｭﾚｰﾀｺｰﾄﾞを XM6 TypeG に
    bra     arg_option                 ; 次のオプション文字へ

@@:
    cmpi.b  #'M',d0                    ; 前の文字とあわせて 'eM' かな？
    bne     @f                         ; 'eM' じゃなかったので次へ

    addq.l  #1,a2                      ; 'eM' だったので引数を一文字すすめる
    move.b  #$03, flag_emulatorcode    ; ｴﾐｭﾚｰﾀｺｰﾄﾞを XM6 TypeG に
    bra     arg_option                 ; 次のオプション文字へ

@@:
    cmpi.b  #'Z',d0                    ; 前の文字とあわせて 'eZ' かな？
    bne     @f                         ; 'eZ' じゃなかったので次へ

    addq.l  #1,a2                      ; 'eZ' だったので引数を一文字すすめる
    move.b  #$04, flag_emulatorcode    ; ｴﾐｭﾚｰﾀｺｰﾄﾞを Z に

    andi.b  #$03,mask_modelcode
    andi.b  #$03,flag_modelcode        ; 初代 フラグ
    bra     set_flag_bootpatch12       ; 12M/STD機動へ

@@:
    cmpi.b  #'N',d0                    ; 前の文字とあわせて 'eN' かな？
    bne     @f                         ; 'eN' じゃなかったので次へ

    addq.l  #1,a2                      ; 'eN' だったので引数を一文字すすめる
    move.b  #$ff, flag_emulatorcode    ; ｴﾐｭﾚｰﾀｺｰﾄﾞを 設定なし に
    bra     arg_option                 ; 次のオプション文字へ

@@:
    bra     help

;-------------------------------------------------------------------------------

arg_filename:
    lea.l filename,a0                  ; ファイル名格納ポインタ
    subq.l  #1,a2                      ; ファイル名一文字目お手つきしてるので戻す
@@:
    move.b  (a2)+,d0
    cmpi.b  #$00,d0                    ; 引数終端かな？
    beq     arg_end                    ; 終端なので終了
    cmpi.b  #' ',d0                    ; スペースかな？
    beq     arg_modelname              ; スペースなら続いてモデル名
    move.b  d0,(a0)+                   ; ファイル名書き込み
    cmpi.b  #$ff,(a0)                  ; 次の書き込み予定地は $ff かな？
    bne     @b                         ; $ff じゃないからループ
    clr.b   (a0)                       ; $ff だったので $00 を書き込み
arg_filename_toolong
    move.b  (a2)+,d0
    cmpi.b  #$00,d0                    ; 引数終端かな？
    beq     arg_end                    ; 終端なので終了
    cmpi.b  #' ',d0                    ; スペースかな？
    bne     arg_filename_toolong       ; スペースじゃなければスキップ

;-------------------------------------------------------------------------------

arg_modelname:
    lea.l modelname,a0                 ; モデル名格納ポインタ
@@:
    move.b  (a2)+,d0
    move.b  d0,(a0)+                   ; モデル名書き込み
    cmpi.b  #$00,d0                    ; 引数終端かな？
    beq     @f                         ; 終端なので次へ
    cmpi.b  #$00,(a0)                  ; 次の書き込み予定は $00 かな？
    beq     arg_end                    ; $00 だったのでこれ以上は書き込みません
    bra     @b                         ; ループ
@@:

;-------------------------------------------------------------------------------

arg_end:
    move.b  filename,d0                ; ファイル名は書き込まれてるかな？
    beq     help                       ; 書き込まれてないのでヘルプ表示

;===============================================================================

file_ready:
    move.w  #-1,-(sp)                  ; ファイル属性取得
    pea.l   filename                   ; ファイル名
    DOS     _CHMOD
    addq.l  #6,sp
    or.l    d0,d0                      ; ファイル属性が
    bpl     @f                         ; 正しく取得できたら次へ

file_notfound:
    pea.l   mes_error_notfound         ; ファイル Not Found
    DOS     _PRINT
    addq.l  #4,sp

    bra     help
@@:

;-------------------------------------------------------------------------------

file_check:
    move.w  d0,-(sp)                   ; 検索ファイル属性
    pea.l   filename                   ; 検索ファイル名
    pea.l   filebuffer                 ; 検索用ファイルバッファ
    DOS     _FILES
    lea.l   10(sp),sp
    or.l    d0,d0                      ; エラーコードが
    bmi     file_notfound              ; 負なら指定ファイルがみつからない

;-------------------------------------------------------------------------------

file_check_X68KROM:
    lea.l   filesize,a0                ; ファイルサイズは
    bsr     fetch_l_d0
    cmpi.l  #$00100000,d0              ; $100000 (1,048,576) bytes ですか
    bne     file_check_IPLROM

    move.b  #1,flag_X68KROM            ; X68KROM.DAT とみなして
    bra     file_check_attr            ; 次へ

file_check_IPLROM:
    cmpi.l  #$00020000,d0              ; $020000 (131,072) bytes ですか
    beq     file_check_attr            ; IPLROM.DAT とみなして次へ

file_mismatch:
    pea.l   mes_error_mismatch         ; パッチ対象外
    DOS     _PRINT
    addq.l  #4,sp

    bra     help                       ; ヘルプ表示

;-------------------------------------------------------------------------------

file_check_attr:
    move.b  fileattr,d0                ; ファイル属性
    andi.b  #$01,d0                    ; リードオンリーチェック
    beq     file_open

file_error_readonly:
    pea.l   mes_error_readonly         ; 読み取り専用属性
    DOS     _PRINT
    addq.l  #4,sp

    bra     help                       ; ヘルプ表示

;===============================================================================

file_open:
    move.w  #$0002,-(sp)               ; R/Wモード
    pea.l   filename                   ; ファイル名
    DOS     _OPEN
    addq.l  #6,sp
    move.l  d0,d1                      ; ファイルハンドル
    bpl     file_seekto_top

    pea     mes_error_open             ; ファイルオープンエラー
    DOS     _PRINT
    addq.l  #4,sp

    bra     help

;-------------------------------------------------------------------------------

file_seekto_top:
    clr.w   -(sp)                      ; ファイルの先頭から
    clr.l   -(sp)                      ; オフセット 0 Byte
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

;-------------------------------------------------------------------------------

file_check_X68KROM_flag:
    move.b  flag_X68KROM,d0            ; X68KROMフラグが
    beq     @f                         ; 立ってなければスキップ

file_case_X68KROM:
    clr.w   -(sp)                      ; ファイルの先頭から
    move.l  #$000e0000,-(sp)           ; オフセット $e0000 Byte (IPLROM先頭)
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $00000000
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー
@@:

;-------------------------------------------------------------------------------

file_seekto_SCSI:                      ; IPLROM $00000000
    move.w  #1,-(sp)                   ; 現在位置 (IPLROM先頭から) から
    move.l  #$00000024,-(sp)           ; オフセット $24 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $00000024
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_check_SCSIINROM:                  ; IPLROM $00000024
    move.l  #6,-(sp)                   ; 読み込むサイズ $06 Bytes
    pea.l   filebuffer                 ; 読み込みバッファ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _READ                      ; IPLROM $0000002a
    lea     10(sp),sp
    or.l    d0,d0                      ; 読み込んだサイズが
    bmi     file_error_nazo            ; 負ならエラー

    cmpi.l  #'SCSI',filebuffer         ; SCSIINROM が入ってる (つまりROM30) かチェック
    bne     @f                         ; 入ってないので IPLROM とみなして次 (オプションチェック) へ

file_case_ROM30:                       ; SCSIINROM が入っていたのでサイズ的に ROM30 確定
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _CLOSE
    addq.l  #2,sp

    bra     file_mismatch              ; ROM30 はパッチ対象外
@@:

;-------------------------------------------------------------------------------

file_check_option:
    move.w  flag_bootpatch,d0          ; bootpatch フラグと logopatch フラグをチェック
    bne     @f                         ; フラグ指定ありなので次 (XEiJ チェック) へ

file_seekto_modelname1:                ; IPLROM $0000002a
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$0001ffb6,-(sp)           ; オフセット $1ffb6 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $0001ffe0
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

    bra     file_check_delete_name     ; モデル名チェックへ
@@:

;-------------------------------------------------------------------------------

file_seekto_XEiJ:                      ; IPLROM $0000002a
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00009fd6,-(sp)           ; オフセット $9fd6 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $0000a000
    addq.l  #8,sp
    or.l    d0,d0                      ; 先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_check_XEiJIPLROM:                 ; IPLROM $0000a000
    move.l  #$10,-(sp)                 ; 読み込むサイズ
    pea.l   filebuffer                 ; 読み込みバッファ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _READ                      ; IPLROM $0000a010
    lea     10(sp),sp
    or.l    d0,d0                      ; 読み込んだサイズが
    bmi     file_error_nazo            ; 負ならエラー

    cmpi.l  #'XEiJ',filebuffer         ; XEiJIPLROM かどうかチェック
    beq     @f                         ; XEiJIPLROM なので次 (オプション別処理) へ

    pea.l   mes_skip_option            ; XEiJIPLROM ではないのでオプション無視しますよ
    DOS     _PRINT
    addq.l  #4,sp

file_seekto_modelname2:                ; IPLROM $0000a010
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00015fd0,-(sp)           ; オフセット $015fd0 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $0001ffe0
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

    bra     file_check_delete_name     ; モデル名処理へ
@@:

;-------------------------------------------------------------------------------

file_check_bootpatch:                  ; IPLROM $0000a010
    move.b  flag_bootpatch,d0          ; bootpatch フラグをチェック
    bne     @f                         ; フラグ指定されているので次 (bootpatch処理) へ

file_seekto_logopatch1:                ; IPLROM $0000a010
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$000072a4,-(sp)           ; オフセット $72a4 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $000112b4
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

    bra     file_check_logopatch       ; logopatch処理へ
@@:

;-------------------------------------------------------------------------------

file_seekto_bootpatch_00:              ; IPLROM $0000a010
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$000069e0,-(sp)           ; オフセット $69e0 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $000109f0
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_bootpatch_00:                     ; IPLROM $000109f0
    move.l  #$08,-(sp)                 ; 上書きサイズ $8 Bytes
    pea.l   bootpatch_00               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $000109f8
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_bootpatch_01:              ; IPLROM $000109f8
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00000008,-(sp)           ; オフセット $8 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $00010a00
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_bootpatch_01:                     ; IPLROM $00010a00
    move.l  #$02,-(sp)                 ; 上書きサイズ $2 Bytes
    pea.l   bootpatch_01               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $00010a02
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_bootpatch_complete:
    pea.l   mes_bootpatched            ; 起動パッチ完了
    DOS     _PRINT
    addq.l  #4,sp

file_seekto_logopatch2:                ; IPLROM $00010a02
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$000008b2,-(sp)           ; オフセット $8b2 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $000112b4
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

;-------------------------------------------------------------------------------

file_check_logopatch                   ; IPLROM $000112b4
    move.b  flag_logopatch,d0          ; logopatch フラグをチェック
    bne     @f                         ; フラグ指定されているので次 (logopatch処理) へ

file_seekto_modelname3:                ; IPLROM $000112b4
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$0000ed2c,-(sp)           ; オフセット $ed2c Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $0001ffe0
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

    bra     file_check_delete_name     ; モデル名処理へ
@@:

;-------------------------------------------------------------------------------

file_logopatch_00:                     ; IPLROM $000112b4
    move.l  #$01,-(sp)                 ; 上書きサイズ $1 Bytes
    pea.l   logopatch_00               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $000112b5
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_logopatch_01:              ; IPLROM $000112b5
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$0000000d,-(sp)           ; オフセット $0d Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $000112c2
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_logopatch_01:                     ; IPLROM $000112c2
    move.l  #$06,-(sp)                 ; 上書きサイズ $6 Bytes
    pea.l   logopatch_01               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $000112c8
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_logopatch_02:              ; IPLROM $000112c8
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00000008,-(sp)           ; オフセット $08 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $000112d0
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_logopatch_02:                     ; IPLROM $000112d0
    move.l  #$06,-(sp)                 ; 上書きサイズ $6 Bytes
    pea.l   logopatch_02               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $000112d6
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_logopatch_03:              ; IPLROM $000112d6
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00000008,-(sp)           ; オフセット $08 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $000112de
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_logopatch_03:                     ; IPLROM $000112de
    move.l  #$06,-(sp)                 ; 上書きサイズ $6 Bytes
    pea.l   logopatch_03               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $000112e4
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_logopatch_04:              ; IPLROM $000112e4
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00000008,-(sp)           ; オフセット $08 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $000112ec
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_logopatch_04:                     ; IPLROM $000112ec
    move.l  #$06,-(sp)                 ; 上書きサイズ $6 Bytes
    pea.l   logopatch_04               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $000112f2
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_logopatch_05:              ; IPLROM $000112f2
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00000008,-(sp)           ; オフセット $08 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $000112fa
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_logopatch_05:                     ; IPLROM $000112fa
    move.l  #$06,-(sp)                 ; 上書きサイズ $6 Bytes
    pea.l   logopatch_05               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $00011300
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_logopatch_06:              ; IPLROM $00011300
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00000008,-(sp)           ; オフセット $08 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $00011308
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_logopatch_06:                     ; IPLROM $00011308
    move.l  #$06,-(sp)                 ; 上書きサイズ $6 Bytes
    pea.l   logopatch_06               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $0001130e
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_logopatch_07:              ; IPLROM $0001130e
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00000005,-(sp)           ; オフセット $05 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $00011313
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_logopatch_07:                     ; IPLROM $00011313
    move.l  #$09,-(sp)                 ; 上書きサイズ $9 Bytes
    pea.l   logopatch_07               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $0001131c
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_logopatch_08:              ; IPLROM $0001131c
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00000008,-(sp)           ; オフセット $08 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $00011324
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_logopatch_08:                     ; IPLROM $00011324
    move.l  #$06,-(sp)                 ; 上書きサイズ $6 Bytes
    pea.l   logopatch_08               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $0001132a
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_logopatch_09:              ; IPLROM $0001132a
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00000008,-(sp)           ; オフセット $08 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $00011332
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_logopatch_09:                     ; IPLROM $00011332
    move.l  #$06,-(sp)                 ; 上書きサイズ $6 Bytes
    pea.l   logopatch_09               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $00011338
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_logopatch_10:              ; IPLROM $00011338
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00000007,-(sp)           ; オフセット $07 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $0001133f
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_logopatch_10:                     ; IPLROM $0001133f
    move.l  #$07,-(sp)                 ; 上書きサイズ $7 Bytes
    pea.l   logopatch_10               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $00011346
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_logopatch_11:              ; IPLROM $00011346
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00000007,-(sp)           ; オフセット $07 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $0001134d
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_logopatch_11:                     ; IPLROM $0001134d
    move.l  #$07,-(sp)                 ; 上書きサイズ $7 Bytes
    pea.l   logopatch_11               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $00011354
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_logopatch_12:              ; IPLROM $00011354
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00000007,-(sp)           ; オフセット $07 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $0001135b
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_logopatch_12:                     ; IPLROM $0001135b
    move.l  #$07,-(sp)                 ; 上書きサイズ $7 Bytes
    pea.l   logopatch_12               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $00011362
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_logopatch_13:              ; IPLROM $00011362
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00000007,-(sp)           ; オフセット $07 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $00011369
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_logopatch_13:                     ; IPLROM $00011369
    move.l  #$07,-(sp)                 ; 上書きサイズ $7 Bytes
    pea.l   logopatch_13               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $00011370
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_logopatch_14:              ; IPLROM $00011370
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00000008,-(sp)           ; オフセット $08 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $00011378
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_logopatch_14:                     ; IPLROM $00011378
    move.l  #$06,-(sp)                 ; 上書きサイズ $6 Bytes
    pea.l   logopatch_14               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $0001137e
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_seekto_logopatch_15:              ; IPLROM $0001137e
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$00000008,-(sp)           ; オフセット $08 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $00011386
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_logopatch_15:                     ; IPLROM $00011386
    move.l  #$01,-(sp)                 ; 上書きサイズ $1 Bytes
    pea.l   logopatch_15               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $00011387
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

file_logopatch_complete:
    pea.l   mes_logopatched            ; ロゴパッチ完了
    DOS     _PRINT
    addq.l  #4,sp

file_seekto_modelname4:                ; IPLROM $00011387
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$0000ec59,-(sp)           ; オフセット $ec59 Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $0001ffe0
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

;-------------------------------------------------------------------------------

file_check_delete_name:                ; IPLROM $0001ffe0
    cmpi.l  #$ffffffff,modelnametag    ; モデル名のタグが
    bne     file_check_modelname       ; 消えてなければ次 (モデル名処理) へ

    lea.l  modelname,a0
@@:
    move.b  #$ff,(a0)+                 ; $ff で埋める
    cmpi.b  #$00,(a0)                  ; 次の書き込み予定は $00 かな？
    bne     @b                         ; $00 ではないのでループ

                                       ; IPLROM $0001fffe
    bra     file_patch_modelname       ; モデル名パッチへ

;-------------------------------------------------------------------------------

file_check_modelname:
    cmpi.b  #$ff,modelname             ; modelname 指定をチェック
    bne     file_patch_modelname       ; 指定されてるのでモデル名パッチへ

;-------------------------------------------------------------------------------

file_read_modelname:                   ; IPLROM $0001ffe0
    move.l  #$1e,-(sp)                 ; 読み込むサイズ $1e Bytes
    pea.l   modelnametag               ; 読み込みバッファ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _READ                      ; IPLROM $0001fffe
    lea     10(sp),sp
    or.l    d0,d0                      ; 読み込んだサイズが
    bmi     file_error_nazo            ; 負ならエラー
    
    cmpi.l  #'NAME',modelnametag       ; モデル名は設定済？
    beq     @f                         ; 設定されているので次へ

    pea.l   mes_no_modelname           ; モデル名は未設定
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_read_emulatorcode     ; 機種ｺｰﾄﾞ 処理へ
@@:
    pea.l   mes_modelname1             ; モデル名(前文)
    DOS     _PRINT
    addq.l  #4,sp
    pea.l   modelname                  ; モデル名
    DOS     _PRINT
    addq.l  #4,sp
    pea.l   mes_modelname2             ; モデル名(後文)
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_read_emulatorcode     ; 機種ｺｰﾄﾞ 処理へ

;-------------------------------------------------------------------------------

file_patch_modelname:                  ; IPLROM $0001ffe0
    move.l  #$1e,-(sp)                 ; 上書きサイズ $1e Bytes
    pea.l   modelnametag               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $0001fffe
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

    cmpi.b  #$ff,modelname             ; モデル名１文字目は $ff かな
    bne     @f                         ; $ff じゃなかったので次 (モデル名表示) へ

file_modelname_deleted:
    pea.l   mes_modelname_deleted      ; 「モデル名を削除しました」
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_read_emulatorcode     ; 終了処理へ
@@:
    pea.l   mes_renamed1               ; モデル名上書き成功(前文)
    DOS     _PRINT
    addq.l  #4,sp

    pea.l   modelname                  ; モデル名
    DOS     _PRINT
    addq.l  #4,sp

    pea.l   mes_renamed2               ; 機名上書き成功(後文)
    DOS     _PRINT
    addq.l  #4,sp

;-------------------------------------------------------------------------------

file_read_emulatorcode:                ; IPLROM $0001fffe
file_read_modelcode:                   ; 
    move.l  #$02,-(sp)                 ; 読み込むサイズ $02 Bytes
    pea.l   emulatorcode               ; 読み込みバッファ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _READ                      ; IPLROM $00020000
    lea     10(sp),sp
    or.l    d0,d0                      ; 読み込んだサイズが
    bmi     file_error_nazo            ; 負ならエラー

    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #-1,-(sp)                  ; オフセット -1 Byte
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $0001ffff
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

file_check_emulatorcode:
    cmpi.b  #$80,flag_emulatorcode     ; emulatorlcode をチェック
    beq     @f                         ; 指定なしなので次へ

    move.b  flag_emulatorcode,d0       ; 指定された emulatorcode を
    move.b  d0,emulatorcode            ; 反映
   
file_patch_emulatorcode:               ; IPLROM $0001ffff
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #-1,-(sp)                  ; オフセット -1 Byte
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $0001fffe
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

    move.l  #$01,-(sp)                 ; 上書きサイズ $01 Bytes
    pea.l   emulatorcode               ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $0001ffff
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

    pea.l   mes_set_emulatorcode1      ; 機種ｺｰﾄﾞ上書き成功(前文)
    DOS     _PRINT
    addq.l  #4,sp

    moveq   #$00, d0
    move.b  emulatorcode,d0            ; 機種ｺｰﾄﾞ
    bsr     print_emulatorcode         ; 表示

    pea.l   mes_set_emulatorcode2      ; 機種ｺｰﾄﾞ上書き成功(後文)
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_check_modelcode       ; modelcode チェックへ

@@:
    cmpi.b  #$ff,emulatorcode          ; ｴﾐｭﾚｰﾀｺｰﾄﾞ は設定済？
    bne     @f                         ; 設定されているので次へ

    pea.l   mes_no_emulatorcode        ; ｴﾐｭﾚｰﾀｺｰﾄﾞ は未設定
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_check_modelcode
@@:
    pea.l   mes_emulatorcode1          ; ｴﾐｭﾚｰﾀｺｰﾄﾞ(前文)
    DOS     _PRINT
    addq.l  #4,sp

    moveq   #$00, d0
    move.b  emulatorcode,d0            ; ｴﾐｭﾚｰﾀｺｰﾄﾞ
    bsr     print_emulatorcode         ; 表示

    pea.l   mes_emulatorcode3          ; ｴﾐｭﾚｰﾀｺｰﾄﾞ(後文)
    DOS     _PRINT
    addq.l  #4,sp

file_check_modelcode:
    cmpi.b  #$ff,mask_modelcode        ; modelcode のマスクをチェック
    bne     file_fix_modelcode         ; 穴があいているので次 (modelcode FIX) へ

    cmpi.b  #$ff,modelcode             ; 機種ｺｰﾄﾞ は設定済？
    bne     @f                         ; 設定されているので次へ

    pea.l   mes_no_modelcode           ; 機種ｺｰﾄﾞ は未設定
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_close                 ; 終了
@@:
    pea.l   mes_modelcode1             ; 機種ｺｰﾄﾞ(前文)
    DOS     _PRINT
    addq.l  #4,sp

    moveq   #$00, d0
    move.b  modelcode,d0               ; 機種ｺｰﾄﾞ
    bsr     print_modelcode            ; 表示

    pea.l   mes_modelcode3             ; 機種ｺｰﾄﾞ(後文)
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_close                 ; 終了

;-------------------------------------------------------------------------------

file_fix_modelcode:                    ; IPLROM $0001ffff
    move.b  mask_modelcode,d0
    and.b   d0,modelcode               ; マスクして
    move.b  flag_modelcode,d0
    or.b    d0,modelcode               ; パッチをあてる
    move.b  modelcode,d0

    cmpi.b  #$ff,d0                    ; 未設定オプションかな？
    bne     modelcode_check            ; 未設定オプションではないので機種ｺｰﾄﾞﾁｪｯｸへ
    
    bra     file_patch_modelcode       ; 機種ｺｰﾄﾞを未設定に

modelcode_check:
    andi.b  #$f4,d0
    cmpi.b  #$24,d0                    ; EXPERT HD かな？
    beq     file_fix_Black             ; EXPERT HD は ﾌﾞﾗｯｸ のみ

    andi.b  #$f0,d0
    tst.b   d0                         ; X68000 初代 かな？
    bne     @f                         ; X68000 初代じゃないので次へ

    andi.b  #$f3,modelcode             ; X68000 初代は I|II や HD なし
    bra     file_fix_modelcolor        ; 色修正
@@:
    cmpi.b  #$10,d0                    ; ACE かな？
    bne     @f                         ; ACE じゃないので次へ

    andi.b  #$f7,modelcode             ; ACE は I|II なし
    bra     file_fix_modelcolor        ; 色修正
@@:
    cmpi.b  #$20,d0                    ; EXPERT かな？
    bne     @f                         ; EXPERT じゃないので次へ

    bra     file_fix_modelcolor        ; 色修正
@@:
    cmpi.b  #$30,d0                    ; PRO かな？
    bne     @f                         ; PRO じゃないので次へ

    bra     file_fix_modelcolor        ; 色修正
@@:
    cmpi.b  #$40,d0                    ; SUPER かな？
    bne     @f                         ; SUPER じゃないので次へ

    andi.b  #$f7,modelcode             ; SUPER は I|II なし
    bra     file_fix_TitanBlack        ; SUPER は ﾁﾀﾝﾌﾞﾗｯｸ のみ
@@:
    cmpi.b  #$50,d0                    ; XVI かな？
    bne     @f                         ; XVI じゃないので次へ

    andi.b  #$f7,modelcode             ; XVI は I|II なし
    bra     file_fix_TitanBlack        ; XVI は ﾁﾀﾝﾌﾞﾗｯｸ のみ
@@:
    cmpi.b  #$60,d0                    ; X68000 Compact かな？
    bne     @f                         ; X68000 Compact じゃないので次へ

    andi.b  #$f7,modelcode             ; X68000 Compact は I|II なし
    bra     file_fix_Gray              ; X68000 Compact は ｸﾞﾚｰ のみ
@@:
    cmpi.b  #$70,d0                    ; X68000 謎機種 かな？
    bne     @f                         ; X68000 謎機種 じゃないので次へ

    andi.b  #$03,modelcode             ; X68000 に修正
    bra     file_fix_modelcolor        ; 色修正
@@:
    cmpi.b  #$80,d0                    ; X68030 かな？
    bne     @f                         ; X68030 じゃないので次へ

    andi.b  #$f7,modelcode             ; X68030 は I|II なし
    bra     file_fix_TitanBlack        ; X68030 は ﾁﾀﾝﾌﾞﾗｯｸ のみ
@@:
    cmpi.b  #$e0,d0                    ; X68030 Compact かな？
    bne     @f                         ; X68030 Compact じゃないので次へ

    andi.b  #$f7,modelcode             ; X68030 Compact は I|II なし
    bra     file_fix_TitanBlack        ; X68030 Compact は ﾁﾀﾝﾌﾞﾗｯｸ のみ
@@:
    andi.b  #$04,modelcode             ; 一旦 X68000 に
    ori.b   #$82,modelcode             ; X68030 に修正
    bra     file_patch_modelcode

file_fix_modelcolor:                   ; 初代|ACE|EXPERT|PRO用色補正
    move.b  modelcode,d0               ; 機種ｺｰﾄﾞを取得
    andi.b  #$03,d0                    ; 色を取り出す
    btst.l  #1, d0                     ; ｵﾌｨｽｸﾞﾚｰ/ｸﾞﾚｰ かな？
    bne     file_fix_Black             ; 違うのでﾌﾞﾗｯｸへ

    move.b  modelcode,d0               ; 機種コードを取得
    andi.b  #$fc,d0                    ; 一旦 ｵﾌｨｽｸﾞﾚｰ に初期化
    tst.b   d0                         ; 初代かな
    bne     file_fix_Gray              ; 初代じゃないので ｸﾞﾚｰ に
file_fix_OfficeGray:
    andi.b  #$fc,modelcode             ; ｵﾌｨｽｸﾞﾚｰ に修正
    bra     file_patch_modelcode
file_fix_Gray:
    andi.b  #$fc,modelcode             ; 一旦 ｵﾌｨｽｸﾞﾚｰ に初期化
    ori.b   #$01,modelcode             ; ｸﾞﾚｰ に修正
    bra     file_patch_modelcode
file_fix_Black
    andi.b  #$fc,modelcode             ; 一旦 ｵﾌｨｽｸﾞﾚｰ に初期化
    ori.b   #$03,modelcode             ; ﾌﾞﾗｯｸ に
    bra     file_patch_modelcode
file_fix_TitanBlack
    andi.b  #$fc,modelcode             ; 一旦 ｵﾌｨｽｸﾞﾚｰ に初期化
    ori.b   #$02,modelcode             ; ﾁﾀﾝﾌﾞﾗｯｸ に
file_patch_modelcode:
    move.l  #$01,-(sp)                 ; 上書きサイズ $01 Bytes
    pea.l   modelcode                  ; 上書きデータ
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _WRITE                     ; IPLROM $00020000
    lea     10(sp),sp
    or.l    d0,d0                      ; 書き込んだサイズが
    bmi     file_error_write           ; 負ならエラー

    cmpi.b  #$ff,modelcode             ; 機種ｺｰﾄﾞ は設定済？
    bne     @f                         ; 設定されているので次へ

file_unset_modelcode:
    pea.l   mes_unset_modelcode        ; 「機種ｺｰﾄﾞを削除しました」
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_close                 ; 終了処理へ
@@:
    pea.l   mes_set_modelcode1         ; 機種ｺｰﾄﾞ上書き成功(前文)
    DOS     _PRINT
    addq.l  #4,sp

    moveq   #$00, d0
    move.b  modelcode,d0               ; 機種ｺｰﾄﾞ
    bsr     print_modelcode            ; 表示

    pea.l   mes_set_modelcode2         ; 機種ｺｰﾄﾞ上書き成功(後文)
    DOS     _PRINT
    addq.l  #4,sp

;-------------------------------------------------------------------------------

file_complete:
    bra     file_close

;-------------------------------------------------------------------------------

file_error_nazo:
    pea.l   mes_error                  ; 謎のエラー (_SEEK/_READ でエラー)
    DOS     _PRINT
    addq.l  #4,sp

    bra    file_close

;-------------------------------------------------------------------------------

file_error_write:
    pea.l   mes_error_write            ; 書き込みエラー
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_close

;-------------------------------------------------------------------------------

file_close:
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _CLOSE
    addq.l  #2,sp

    DOS     _EXIT

;===============================================================================

help:
    pea.l   mes_help                   ; ヘルプ
    DOS     _PRINT
    addq.l  #4,sp

    DOS     _EXIT

;===============================================================================

print_emulatorcode:                       ; ｴﾐｭﾚｰﾀｺｰﾄﾞ表示
    bsr     printb

    pea.l   mes_emulatorcode2
    DOS     _PRINT
    addq.l  #4,sp

    move.b  emulatorcode,d0               ; 機種ｺｰﾄﾞ
    cmp.b   #$00,d0
    bne     @f

    pea.l   mes_Jikki
    DOS     _PRINT
    addq.l  #4,sp

    rts

@@:
    cmp.b   #$01,d0
    bne     @f

    pea.l   mes_XEiJ
    DOS     _PRINT
    addq.l  #4,sp

    rts

@@:
    cmp.b   #$02,d0
    bne     @f

    pea.l   mes_XM6TypeG
    DOS     _PRINT
    addq.l  #4,sp

    rts

@@:
    cmp.b   #$03,d0
    bne     @f

    pea.l   mes_MiSTer
    DOS     _PRINT
    addq.l  #4,sp

    rts

@@:
    cmp.b   #$04,d0
    bne     @f

    pea.l   mes_Z
    DOS     _PRINT
    addq.l  #4,sp

    rts

@@:
    pea.l   mes_noset
    DOS     _PRINT
    addq.l  #4,sp

    rts

;===============================================================================

print_modelcode:                       ; 機種ｺｰﾄﾞ表示
    move.b  d0,-(sp)
    bsr    printb

    pea.l  mes_modelcode2
    DOS     _PRINT
    addq.l  #4,sp

print_modelcode_bit7:                  ; X68000|X68030 フラグ
    move.b  (sp),d0
    andi.b  #$80,d0
    bne     @f

    pea.l   mes_X68000                 ; X68000
    bra     @@f
@@:
    pea.l   mes_X68030                 ; X68030
@@:
    DOS     _PRINT
    addq.l  #4,sp

print_modelcode_bit654:                ; ACE|EXPERT|PRO|SUPER|XVI|Compact フラグ
    move.b  (sp),d0
    andi.b  #$70,d0
    beq     print_modelcode_bit3
1:
    cmpi.b  #$10,d0
    bne     2f
    pea.l   mes_ACE                    ; ACE
    bra     @f
2:
    cmpi.b  #$20,d0
    bne     3f
    pea.l   mes_EXPERT                 ; EXPERT
    bra     @f
3:
    cmpi.b  #$30,d0
    bne     4f
    pea.l   mes_PRO                    ; PRO
    bra     @f
4:
    cmpi.b  #$40,d0
    bne     5f
    pea.l   mes_SUPER                  ; SUPER
    bra     @f
5:
    cmpi.b  #$50,d0
    bne     6f
    pea.l   mes_XVI                    ; XVI
    bra     @f
6:
    cmpi.b  #$60,d0
    bne     print_modelcode_end
    pea.l   mes_Compact                ; Compact
@@:
    DOS     _PRINT
    addq.l  #4,sp

print_modelcode_bit3:
    move.b  (sp),d0
    andi.b  #$08,d0
    beq     print_modelcode_bit2

    pea.l   mes_II                     ; II
    DOS     _PRINT
    addq.l  #4,sp

print_modelcode_bit2:
    move.b  (sp),d0
    andi.b  #$04,d0
    beq     print_modelcode_bit10

    pea.l   mes_HD                     ; HD
    DOS     _PRINT
    addq.l  #4,sp

print_modelcode_bit10:                 ; OfficeGray|Gray|TitanBlack|Black フラグ
    move.b  (sp),d0
    andi.b  #$03,d0
    bne     1f
0:
    pea.l   mes_OfficeGray             ; ｵﾌｨｽｸﾞﾚｰ
    bra     @f
1:
    cmpi.b  #$01,d0
    bne     2f
    pea.l   mes_Gray                   ; ｸﾞﾚｰ
    bra     @f
2:
    cmpi.b  #$02,d0
    bne     3f
    pea.l   mes_TitanBlack             ; ﾁﾀﾝﾌﾞﾗｯｸ
    bra     @f
3:
    pea.l   mes_Black                  ; ﾌﾞﾗｯｸ
@@:
    DOS     _PRINT
    addq.l  #4,sp

print_modelcode_end:
    move.b (sp)+,d0
    rts

;===============================================================================

printl:
    move.l  d1,-(sp)
    move.l  d2,-(sp)

    move.l  d0,d1
    moveq   #7,d2                      ; カウンタ
@@:
    rol.l   #4,d1
    move.l  d1,d0
    bsr     printq
    dbra    d2,@b

    move.l (sp)+,d2
    move.l (sp)+,d1
    rts
;
printb:
    move.l  d0,-(sp)

    ror.l   #4,d0
    bsr     printq
    move.l   (sp),d0
    bsr     printq

    move.l  (sp)+,d0
    rts
;
printq:
    andi.w  #$0f,d0
    ori.w   #$30,d0
    cmpi.w  #$3a,d0
    blt     @f
    addq.w  #7,d0
@@:
    move.w  d0,-(sp)
    DOS     _PUTCHAR
    addq.l  #2,sp

    rts

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

fetch_l_d0:
    move.b  (a0)+,d0
    rol.l   #8,d0
    move.b  (a0)+,d0
    rol.l   #8,d0
    move.b  (a0)+,d0
    rol.l   #8,d0
    move.b  (a0)+,d0
    rts

;===============================================================================

    .data
    .even

;===============================================================================

bootpatch_00:
    .dc.b   $00,$40,$00,$00,$00,$fc,$00,$00
bootpatch_01:
    .dc.b   $00,00
logopatch_00:
    .dc.b               $08
logopatch_01:
    .dc.b               $08,$1f,$f0,$00,$07,$fc
logopatch_02:
    .dc.b               $08,$7f,$f8,$00,$1f,$fe
logopatch_03:
    .dc.b               $10,$e0,$38,$00,$38,$0e
logopatch_04:
    .dc.b               $10,$c0,$18,$00,$30,$06
logopatch_05:
    .dc.b               $32,$c0,$1b,$87,$30,$06
logopatch_06:
    .dc.b               $35,$80,$31,$ce,$60,$0c
logopatch_07:
    .dc.b   $ff,$9f,$fc,$79,$80,$30,$dc,$60,$0c
logopatch_08:
    .dc.b               $79,$80,$30,$f8,$60,$0c
logopatch_09:
    .dc.b               $b1,$80,$30,$70,$40,$0c
logopatch_10:
    .dc.b           $0d,$33,$00,$60,$f0,$c0,$18
logopatch_11:
    .dc.b           $0c,$23,$00,$61,$f0,$c0,$18
logopatch_12:
    .dc.b           $1c,$23,$80,$e3,$b8,$e0,$38
logopatch_13:
    .dc.b           $f8,$43,$ff,$c7,$18,$ff,$f0
logopatch_14:
    .dc.b               $41,$ff,$8e,$1c,$7f,$c0
logopatch_15:
    .dc.b               $40

;-------------------------------------------------------------------------------

    .data
    .even

;-------------------------------------------------------------------------------
flag_bootpatch:
    .ds.b   1
flag_logopatch:
    .ds.b   1
mask_modelcode:
    .dc.b   $ff
flag_emulatorcode:
    .dc.b   $80
flag_modelcode:
    .ds.b   1
flag_X68KROM:
    .ds.b   1
;-------------------------------------------------------------------------------

    .data
    .even

;-------------------------------------------------------------------------------
filebuffer:
    .ds.b   21
fileattr:
    .ds.b   1
filetimedate:
    .ds.b   4
filesize:
    .ds.b   4
filename:
    .dc.b   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .dc.b   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ff
    .even
modelnametag:
    .dc.b   'NAME'
modelname:
    .dc.b                   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    .dc.b   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00
emulatorcode:
    .dc.b   $00
modelcode:
    .dc.b   $00
mes_error:
    .dc.b   '再起動してから改めてお試しくださいませ！',$0d,$0a,$0d,$0a,$0
mes_error_mismatch:
    .dc.b   'ご指定のファイルはパッチ対象外です(TдT)',$0d,$0a,$0d,$0a,$0
mes_error_readonly:
    .dc.b   'ご指定のファイルは読み取り専用属性です(TдT)',$0d,$0a,$0d,$0a,$0
mes_error_notfound:
    .dc.b   'ご指定のファイルが見つかりません(TдT)',$0d,$0a,$0d,$0a,$0
mes_error_open:
    .dc.b   'ファイルを開けませんでした(TдT)',$0d,$0a,$0d,$0a,$0
mes_error_write:
    .dc.b   'ファイルを更新できませんでした(TдT)',$0d,$0a,$0d,$0a,$0
mes_skip_option:
    .dc.b   'XEiJ の IPLROM ではないため、オプション指定を既読スルーします！',$0d,$0a,$0d,$0a,$0
mes_bootpatched:
    .dc.b   '4MB/STD起動に設定しました！',$0d,$0a,00
mes_logopatched:
    .dc.b   '起動ロゴを X680x0 に設定しました！',$0d,$0a,00
mes_modelname_deleted:
    .dc.b   'モデル名情報を削除しました！',$0d,$0a,$00
mes_no_modelname:
    .dc.b   'モデル名は 未設定 です！',$0d,$0a,$00
mes_modelname1:
    .dc.b   'モデル名は [',$00
mes_modelname2:
    .dc.b   '] です！',$0d,$0a,$00
mes_renamed1:
    .dc.b   'モデル名を [',$00
mes_renamed2:
    .dc.b   '] に設定しました！',$0d,$0a,$00
mes_unset_modelcode:
    .dc.b   '機種ｺｰﾄﾞ情報を削除しました！',$0d,$0a,$0d,$0a,$00
mes_no_emulatorcode:
    .dc.b   'ｴﾐｭﾚｰﾀｺｰﾄﾞは 未設定 です！',$0d,$0a,$00
mes_emulatorcode1:
    .dc.b   'ｴﾐｭﾚｰﾀｺｰﾄﾞは $',$00
mes_emulatorcode2:
    .dc.b   ' - ',$00
mes_emulatorcode3:
    .dc.b   ' です！',$0d,$0a,$00
mes_set_emulatorcode1:
    .dc.b   'ｴﾐｭﾚｰﾀｺｰﾄﾞを $',$00
mes_set_emulatorcode2:
    .dc.b   ' に設定しました！',$0d,$0a,$00
mes_no_modelcode:
    .dc.b   '機種ｺｰﾄﾞは 未設定 です！',$0d,$0a,$0d,$0a,$00
mes_modelcode1:
    .dc.b   '機種ｺｰﾄﾞは $',$00
mes_modelcode2:
    .dc.b   ' - ',$00
mes_modelcode3:
    .dc.b   ' です！',$0d,$0a,$0d,$0a,$00
mes_set_modelcode1:
    .dc.b   '機種ｺｰﾄﾞを $',$00
mes_set_modelcode2:
    .dc.b   ' に設定しました！',$0d,$0a,$0d,$0a,$00
mes_X68000:
    .dc.b   'X68000',$00
mes_X68030:
    .dc.b   'X68030',$00
mes_ACE:
    .dc.b   ' ACE',$00
mes_EXPERT:
    .dc.b   ' EXPERT',$00
mes_PRO:
    .dc.b   ' PRO',$00
mes_SUPER:
    .dc.b   ' SUPER',$00
mes_XVI:
    .dc.b   ' XVI',$00
mes_Compact:
    .dc.b   ' Compact',$00
mes_II:
    .dc.b   ' II',$00
mes_HD:
    .dc.b   '-HD',$00
mes_OfficeGray:
    .dc.b   ' (ｵﾌｨｽｸﾞﾚｰ)',$00
mes_Gray:
    .dc.b   ' (ｸﾞﾚｰ)',$00
mes_TitanBlack:
    .dc.b   ' (ﾁﾀﾝﾌﾞﾗｯｸ)',$00
mes_Black:
    .dc.b   ' (ﾌﾞﾗｯｸ)',$00
mes_Jikki:
    .dc.b   '実機',$00
mes_XEiJ:
    .dc.b   'XEiJ',$00
mes_XM6TypeG:
    .dc.b   'XM6 TypeG',$00
mes_MiSTer:
    .dc.b   'MiSTER',$00
mes_Z:
    .dc.b   'X68000 Z',$00
mes_noset:
    .dc.b   '設定なし',$00
mes_title:
    .dc.b   'ROMPatch ',$00
mes_version:
    .dc.b   $f3,'v',$f3,'e',$f3,'r',$f3,'s',$f3,'i',$f3,'o',$f3,'n',$f3,' ',$f3,'1',$f3,'.',$f3,'2',$f3,'4',$00
mes_by:
    .dc.b   ' ',$f3,'b',$f3,'y ',$00
mes_author:
    .dc.b   'みゆ (miyu rose)',$0d,$0a,$0d,$0a,$0
mes_help:
    .dc.b   ' ROMPatch.x ([options]) [filename] ([modelname])',$0d,$0a
    .dc.b   '  [options]',$0d,$0a
    .dc.b   '   -d|u           : モデル名|機種ｺｰﾄﾞ の情報を削除します',$0d,$0a
    .dc.b   '   -0|3           : 機種ｺｰﾄﾞ を 初代|X68030 にします',$0d,$0a
    .dc.b   '   -A|E|P         : 機種ｺｰﾄﾞ を ACE|EXPERT|PRO にします',$0d,$0a
    .dc.b   '   -S|X|C         : 機種ｺｰﾄﾞ を SUPER|XVI|Compact にします',$0d,$0a
    .dc.b   '   -I|II          : 機種ｺｰﾄﾞ に I|II を付加します',$0d,$0a
    .dc.b   '   -HD|N          : 機種ｺｰﾄﾞ に HD を付加|除去します',$0d,$0a
    .dc.b   '   -O|G|B|T       : 機種ｺｰﾄﾞ の色を ｵﾌｨｽｸﾞﾚｰ|ｸﾞﾚｰ|ﾌﾞﾗｯｸ|ﾁﾀﾝﾌﾞﾗｯｸ にします',$0d,$0a
    .dc.b   '   -1M|2M|4M|12M  : 指定の標準メモリ/STD起動にします',$0d,$0a
    .dc.b   '   -eR|eJ|eG|eM|eZ: ｴﾐｭﾚｰﾀｺｰﾄﾞ を 実機|XEiJ|XM6 TypeG|MiSTer|Z にします',$0d,$0a
    .dc.b   '   -eN            : ｴﾐｭﾚｰﾀｺｰﾄﾞ を 設定なし にします',$0d,$0a
    .dc.b   '   -x             : 起動ロゴを X680x0 にします (for XEiJ IPLROM)',$0d,$0a
    .dc.b   '   -h             : ヘルプを表示します',$0d,$0a
    .dc.b   ' [filename]',$0d,$0a
    .dc.b   '  パッチをあてる IPLROM ($fe0000-$ffffff) または',$0d,$0a
    .dc.b   '  X68KROM ($f00000-$ffffff) のダンプファイルです',$0d,$0a
    .dc.b   ' [modelname]',$0d,$0a
    .dc.b   '  指定のモデル名(X68000 PhantomX 等)にリネームします',$0d,$0a
    .dc.b   '  指定しない場合は現在設定中のモデル名を表示します',$0d,$0a
mes_crlf:
    .dc.b   $0d,$0a
mes_nul:
    .dc.b   $00

;===============================================================================

    .stack
    .even

;===============================================================================

mystack:
    .ds.l   256
mysp:
    .end    main

;===============================================================================
