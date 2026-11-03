;===============================================================================
;
; ROMPatch.x version 1.27 by みゆ (miyu rose)
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
;    -x=logo_file   : 指定ファイルから起動ロゴを設定します (DAT/ROM/TXT)
;    -h|?           : ヘルプを表示します
;   [filename]
;    パッチをあてる IPLROM ($fe0000-$ffffff) または
;    FULLROM ($f00000-$ffffff) のダンプファイルです
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
;  X68000 Z        = $04
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
    move.b  #'2',(a0)+                 ; 12MB
    move.b  #'M',(a0)                  ; にする

    bra     arg_option                 ; 次のオプション文字へ

@@:
    addq.l  #1,a2                      ; '1M' だったので引数を一文字すすめる
set_flag_bootpatch1:
    move.b  #1,flag_bootpatch          ; bootpatch フラグを立てる
    lea.l   bootpatch_00,a0
    move.l  #$00100000,(a0)            ; 書き込むデータを 1MB にする
    lea.l   mes_bootpatched,a0
    move.b  #'1',(a0)+                 ; 表示メッセージを
    move.b  #'M',(a0)+                 ; 1MB
    move.b  #'B',(a0)                  ; にする

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
    move.b  #'M',(a0)+                 ; 2MB
    move.b  #'B',(a0)                  ; にする

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
    move.b  #'M',(a0)+                 ; 4MB
    move.b  #'B',(a0)                  ; にする

    bra     arg_option                 ; 次のオプション文字へ

;-------------------------------------------------------------------------------

arg_flag_logopatch:
    move.b  #1,flag_logopatch          ; 従来の -x は内蔵ロゴを使用する
    cmpi.b  #'=',(a2)                  ; 続く文字が '=' かな？
    bne     arg_option                 ; '=' じゃないので従来どおり次のオプション文字へ

arg_logo_filename:                     ; -x=ファイル名 の取得
    addq.l  #1,a2                      ; '=' を読み飛ばす
    lea.l   logo_filename,a0           ; ロゴファイル名格納ポインタ
    lea.l   logo_filename+255,a1       ; 終端 $00 のため最後の1バイトは空けておく
    cmpi.b  #$00,(a2)                  ; ファイル名は指定されているかな？
    beq     help                       ; 空なので書式エラー
    cmpi.b  #' ',(a2)                  ; '=' の直後がスペースかな？
    beq     help                       ; ファイル名がないので書式エラー
@@:                                    ; ファイル名の続きを取得する
    move.b  (a2),d0                    ; 次の1文字を取得
    beq     arg_logo_filename_end      ; 引数終端なのでファイル名取得完了
    cmpi.b  #' ',d0                    ; スペースかな？
    beq     arg_logo_filename_end      ; 次の引数なのでファイル名取得完了
    cmpa.l  a1,a0                      ; ファイル名の格納領域は残っているかな？
    bhs     help                       ; 長すぎるファイル名は受け付けない
    move.b  (a2)+,(a0)+                ; ファイル名を1文字コピー
    bra     @b                         ; 次の文字へ
arg_logo_filename_end:                 ; ファイル名の取得を終了する
    clr.b   (a0)                       ; ファイル名の末尾に $00 を追加
    move.b  #2,flag_logopatch          ; 外部ファイル指定のロゴパッチにする
    bra     arg_skip                   ; 引数の区切りから解析を再開する

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
    bra     set_flag_bootpatch2        ; 2MB/STD機動へ

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
    andi.b #$03,mask_modelcode
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
    andi.b  #$fc,flag_modelcode        ; 色ビットのみ初期化
    ori.b   #$02,flag_modelcode        ; ﾁﾀﾝﾌﾞﾗｯｸ に
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
    move.b  #$02, flag_emulatorcode    ; ｴﾐｭﾚｰﾀｺｰﾄﾞを XM6 TypeG に
    bra     arg_option                 ; 次のオプション文字へ

@@:
    cmpi.b  #'M',d0                    ; 前の文字とあわせて 'eM' かな？
    bne     @f                         ; 'eM' じゃなかったので次へ

    addq.l  #1,a2                      ; 'eM' だったので引数を一文字すすめる
    move.b  #$03, flag_emulatorcode    ; ｴﾐｭﾚｰﾀｺｰﾄﾞを MiSTer に
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
    move.b  filename,d0                ; パッチ対象ファイル名は書き込まれているかな？
    beq     help                       ; 書き込まれてないのでヘルプ表示
    cmpi.b  #2,flag_logopatch          ; -x= で外部ロゴが指定されているかな？
    bne     file_ready                 ; 外部ロゴ指定がないので通常のファイル処理へ
    bsr     logo_load                  ; 外部ロゴを読み込み、内容をすべて検証する
    tst.l   d0                         ; 読み込み・検証は成功したかな？
    bmi     logo_error                 ; 異常があれば対象ROMを開く前に終了する

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

file_check_FULLROM:
    lea.l   filesize,a0                ; ファイルサイズは
    bsr     fetch_l_d0
    cmpi.l  #$00100000,d0              ; $100000 (1,048,576) bytes ですか
    bne     file_check_IPLROM

    move.b  #1,flag_FULLROM            ; FULLROM.DAT とみなして
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

file_check_FULLROM_flag:
    move.b  flag_FULLROM,d0            ; FULLROMフラグが
    beq     @f                         ; 立ってなければスキップ

file_case_FULLROM:
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
    cmpi.b  #2,d0                      ; 外部ロゴファイルが指定されているかな？
    beq     file_logopatch_external    ; 指定されているのでFNTBUF全体の書き込みへ
    tst.b   d0                         ; 従来の -x が指定されているかな？
    bne     file_logopatch_builtin     ; 内蔵ロゴ全体を正しいサイズで設定する

file_seekto_modelname3:                ; IPLROM $000112b4
    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #$0000ed2c,-(sp)           ; オフセット $ed2c Bytes
    move.w  d1,-(sp)                   ; ファイルハンドル
    DOS     _SEEK                      ; IPLROM $0001ffe0
    addq.l  #8,sp
    or.l    d0,d0                      ; ファイル先頭からのオフセットが
    bmi     file_error_nazo            ; 負ならエラー

    bra     file_check_delete_name     ; モデル名処理へ

;-------------------------------------------------------------------------------

file_logopatch_builtin:                ; 従来の -x は内蔵ロゴを全体で復元する
    move.w  #112,logo_width            ; 内蔵ロゴの横幅は112ドット
    move.w  #228,logo_length           ; FNTBUF全体の長さは228バイト
    lea.l   logo_builtin,a0            ; ROMPatch内蔵の完成済みX680x0ロゴ
    bsr     logo_copy_fnt              ; 以前の外部ロゴの残りを使わず全体をコピー
    bra     file_logopatch_external    ; 外部ロゴと共通の安全な上書き処理へ

;-------------------------------------------------------------------------------

file_logopatch_external:               ; -x= はFNTBUF全体を上書きする
    move.l  #$000112a8,d0              ; IPLROM内のロゴ先頭位置 $112a8
    tst.b   flag_FULLROM               ; 対象ファイルはFULLROMかな？
    beq     @f                         ; IPLROMなのでこのまま
    addi.l  #$000e0000,d0              ; FULLROMの場合はIPLROMの開始位置を加算
@@:                                    ; 対象ROMのロゴ先頭アドレスを確定する
    clr.w   -(sp)                      ; ファイルの先頭から
    move.l  d0,-(sp)                   ; ロゴ先頭までのオフセット
    move.w  d1,-(sp)                   ; 対象ROMのファイルハンドル
    DOS     _SEEK                      ; ロゴ先頭へ移動
    addq.l  #8,sp                      ; _SEEKの引数8バイトを取り除く
    or.l    d0,d0                      ; シークに成功したかな？
    bmi     file_error_nazo            ; 負ならエラー

    moveq   #0,d2                      ; 長さを32ビットで扱えるようにする
    move.w  logo_length,d2             ; 検証済みのFNTBUF全体のバイト数
    move.l  d2,-(sp)                   ; 上書きするバイト数
    pea.l   logo_buffer                ; 幅・高さを含むFNTBUFデータ
    move.w  d1,-(sp)                   ; 対象ROMのファイルハンドル
    DOS     _WRITE                     ; ロゴデータを一括書き込み
    lea.l   10(sp),sp                  ; _WRITEの引数10バイトを取り除く
    cmp.l   d2,d0                      ; 指定したバイト数をすべて書き込めたかな？
    bne     file_error_write           ; 書き込み不足やエラーなら終了する

    cmpi.w  #112,logo_width            ; 標準の112ドットよりも幅が広いかな？
    bls     file_logo_restore_series   ; 標準以下なら以前の拡張ロゴ指定を解除する
    bra     file_logopatch_hide_series ; 標準幅を超えるのでSERIES表示を消す

file_logo_restore_series:              ; 標準幅へ戻す場合はSERIES表示を復元する
    move.l  #$000111c4,d0              ; IPLROM内のSERIES表示文字列の位置
    tst.b   flag_FULLROM               ; 対象ファイルはFULLROMかな？
    beq     @f                         ; IPLROMなのでこのまま
    addi.l  #$000e0000,d0              ; FULLROMの場合はIPLROMの開始位置を加算
@@:                                    ; 対象ROMのSERIES表示位置を確定する
    clr.w   -(sp)                      ; ファイルの先頭から
    move.l  d0,-(sp)                   ; SERIES表示位置までのオフセット
    move.w  d1,-(sp)                   ; 対象ROMのファイルハンドル
    DOS     _SEEK                      ; SERIES表示位置へ移動
    addq.l  #8,sp                      ; _SEEKの引数8バイトを取り除く
    or.l    d0,d0                      ; シークに成功したかな？
    bmi     file_error_nazo            ; 負ならエラー

    move.l  #3,-(sp)                   ; 確認するのは先頭3バイトのみ
    pea.l   logo_series_check          ; 読み込みバッファ
    move.w  d1,-(sp)                   ; 対象ROMのファイルハンドル
    DOS     _READ                      ; 現在のSERIES表示設定を読む
    lea.l   10(sp),sp                  ; _READの引数10バイトを取り除く
    cmpi.l  #3,d0                      ; 3バイトを読み込めたかな？
    bne     file_error_nazo            ; 読み込み不足やエラーなら終了する
    cmpi.b  #$0d,logo_series_check     ; 拡張ロゴのCR/LF/NULが残っているかな？
    bne     file_logo_complete         ; 別のデータならユーザーの内容を保つ
    cmpi.b  #$0a,logo_series_check+1   ; 2バイト目はLFかな？
    bne     file_logo_complete         ; 違うなら変更しない
    tst.b   logo_series_check+2        ; 3バイト目はNULかな？
    bne     file_logo_complete         ; 違うなら変更しない

    move.w  #1,-(sp)                   ; 現在位置から
    move.l  #-3,-(sp)                  ; 読み込んだ3バイトの位置へ戻す
    move.w  d1,-(sp)                   ; 対象ROMのファイルハンドル
    DOS     _SEEK                      ; SERIES表示位置へ戻す
    addq.l  #8,sp                      ; _SEEKの引数8バイトを取り除く
    or.l    d0,d0                      ; シークに成功したかな？
    bmi     file_error_nazo            ; 負ならエラー

    move.l  #3,-(sp)                   ; 上書きサイズは3バイト
    pea.l   logo_series_spaces         ; 既定の空白3バイトに戻す
    move.w  d1,-(sp)                   ; 対象ROMのファイルハンドル
    DOS     _WRITE                     ; SERIES表示を復元する
    lea.l   10(sp),sp                  ; _WRITEの引数10バイトを取り除く
    cmpi.l  #3,d0                      ; 3バイトすべてを書き込めたかな？
    bne     file_error_write           ; 書き込み不足やエラーなら終了する
    bra     file_logo_complete         ; 以降は共通の完了処理へ

file_logopatch_hide_series:            ; 拡張ロゴのためにSERIES表示を抑止する
    move.l  #$000111c4,d0              ; IPLROM内のSERIES表示文字列の位置
    tst.b   flag_FULLROM               ; 対象ファイルはFULLROMかな？
    beq     @f                         ; IPLROMなのでこのまま
    addi.l  #$000e0000,d0              ; FULLROMの場合はIPLROMの開始位置を加算
@@:                                    ; 対象ROMのSERIES表示位置を確定する
    clr.w   -(sp)                      ; ファイルの先頭から
    move.l  d0,-(sp)                   ; SERIES表示位置までのオフセット
    move.w  d1,-(sp)                   ; 対象ROMのファイルハンドル
    DOS     _SEEK                      ; SERIES表示位置へ移動
    addq.l  #8,sp                      ; _SEEKの引数8バイトを取り除く
    or.l    d0,d0                      ; シークに成功したかな？
    bmi     file_error_nazo            ; 負ならエラー

    move.l  #3,-(sp)                   ; 上書きサイズは3バイト
    pea.l   logo_series_crlf           ; CR/LF/NULに置き換えてSERIESを表示しない
    move.w  d1,-(sp)                   ; 対象ROMのファイルハンドル
    DOS     _WRITE                     ; SERIES表示の抑止パッチ
    lea.l   10(sp),sp                  ; _WRITEの引数10バイトを取り除く
    cmpi.l  #3,d0                      ; 3バイトすべてを書き込めたかな？
    bne     file_error_write           ; 書き込み不足やエラーなら終了する

file_logo_complete:                    ; 指定されたロゴパッチの完了メッセージを表示する
    cmpi.b  #1,flag_logopatch          ; 内蔵ロゴの -x だったかな？
    bne     @f                         ; 外部ロゴなので別のメッセージを使う
    pea.l   mes_logopatched            ; 従来のX680x0ロゴを設定したメッセージ
    bra     file_logo_complete_print   ; 共通の完了表示へ
@@:                                    ; -x= のロゴ適用メッセージ
    pea.l   mes_logo_file_patched      ; 外部ファイルのロゴを設定したことを表示
file_logo_complete_print:              ; それぞれの完了メッセージを出力する
    DOS     _PRINT                     ; 完了メッセージを表示する
    addq.l  #4,sp                      ; _PRINTの引数4バイトを取り除く

file_seekto_modelname4:                ; 各ロゴパッチの終了位置から共通のモデル名処理へ
    move.l  #$0001ffe0,d0              ; IPLROM内のモデル名先頭位置
    tst.b   flag_FULLROM               ; 対象ファイルはFULLROMかな？
    beq     @f                         ; IPLROMなのでこのまま
    addi.l  #$000e0000,d0              ; FULLROMの場合はIPLROMの開始位置を加算
@@:                                    ; モデル名の書き換え位置を確定する
    clr.w   -(sp)                      ; ファイルの先頭から
    move.l  d0,-(sp)                   ; モデル名先頭位置
    move.w  d1,-(sp)                   ; 対象ROMのファイルハンドル
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
;
; ロゴファイルの読み込みと検証
;  -x= の入力は対象ROMを開く前にすべて検査する
;  エラー時には元のROMを変更せずに終了できるようにする
;
;===============================================================================

logo_load:                             ; 指定ロゴファイルを開いて内容を検証する
    clr.w   -(sp)                      ; ロゴファイルを読み込み専用で開く
    pea.l   logo_filename              ; -x= で指定されたファイル名
    DOS     _OPEN                      ; ロゴファイルを読み込み専用で開く
    addq.l  #6,sp                      ; _OPENの引数6バイトを取り除く
    or.l    d0,d0                      ; ファイルを開けたかな？
    bmi     logo_load_open_error       ; 負ならオープンエラー
    move.w  d0,logo_handle             ; ロゴファイルのハンドルを保存

    move.w  #2,-(sp)                   ; ファイルの末尾から
    clr.l   -(sp)                      ; オフセット0バイト
    move.w  logo_handle,-(sp)          ; ロゴファイルのハンドル
    DOS     _SEEK                      ; ファイルサイズを取得
    addq.l  #8,sp                      ; _SEEKの引数8バイトを取り除く
    or.l    d0,d0                      ; ファイルサイズを取得できたかな？
    bmi     logo_load_io_error         ; 負なら読み込みエラー
    move.l  d0,logo_filesize           ; 判定に使うファイルサイズを保存

    cmpi.l  #$00020000,d0              ; 128KBのIPLROMイメージかな？
    beq     logo_load_rom128           ; ROM内のロゴ位置から読み込む
    cmpi.l  #$00100000,d0              ; 1MBのFULLROMイメージかな？
    beq     logo_load_rom1024          ; ROM内のロゴ位置から読み込む
    tst.l   d0                         ; 空のファイルかな？
    beq     logo_load_format_error     ; 空ならロゴとして扱えない
    cmpi.l  #3360,d0                   ; テキスト16行の最大サイズを超えているかな？
    bhi     logo_load_size_error       ; 上限超過なら読み込まない

logo_load_small:                       ; FNTBUFバイナリまたはテキスト
    clr.w   -(sp)                      ; ファイルの先頭から
    clr.l   -(sp)                      ; オフセット0バイト
    move.w  logo_handle,-(sp)          ; ロゴファイルのハンドル
    DOS     _SEEK                      ; ファイルの先頭に戻す
    addq.l  #8,sp                      ; _SEEKの引数8バイトを取り除く
    or.l    d0,d0                      ; シークに成功したかな？
    bmi     logo_load_io_error         ; 負なら読み込みエラー

    move.l  logo_filesize,-(sp)        ; 読み込むバイト数
    pea.l   logo_textbuffer            ; いったん共通の入力バッファへ
    move.w  logo_handle,-(sp)          ; ロゴファイルのハンドル
    DOS     _READ                      ; 入力ファイルをまとめて読み込む
    lea.l   10(sp),sp                  ; _READの引数10バイトを取り除く
    cmp.l   logo_filesize,d0           ; ファイル末尾まで読み込めたかな？
    bne     logo_load_io_error         ; 読み込み不足やエラーなら終了する

    move.l  logo_filesize,d2           ; FNTBUF判定で使うファイル全体の長さ
    cmpi.l  #4,d2                      ; FNTBUFのヘッダ4バイトはあるかな？
    blo     logo_load_text             ; ないのでテキストとして検査する
    lea.l   logo_textbuffer,a0         ; FNTBUF候補の先頭
    cmpi.w  #16,2(a0)                  ; 高さ16ドットのバイナリヘッダかな？
    bne     logo_load_text             ; 違うのでテキストとして検査する
    moveq   #0,d0                      ; 横幅を符号なしとして扱う
    move.w  (a0),d0                    ; バイナリの横幅を取得する
    cmpi.w  #208,d0                    ; 横幅208ドット以内かな？
    bhi     logo_load_size_error       ; 超過ならデータサイズエラーにする
    bsr     logo_check_fnt_header      ; 幅・高さから必要なデータサイズを取得
    tst.l   d0                         ; 正しいヘッダだったかな？
    bmi     logo_load_format_error     ; バイナリヘッダが不正なので形式エラー
    cmp.l   d2,d0                      ; ヘッダから計算したサイズと一致するかな？
    bne     logo_load_format_error     ; 一致しなければ形式エラー
    move.w  d0,logo_length             ; FNTBUF全体の長さを確定する
    bsr     logo_copy_fnt              ; ロゴデータをバッファへコピーする
    moveq   #0,d0                      ; 読み込み成功
    bra     logo_load_close            ; ロゴファイルを閉じる

logo_load_text:                        ; # と . のビットマップ形式
    bsr     logo_parse_text            ; 16行の全データを検査してFNTBUFへ変換
    bra     logo_load_close            ; 結果を保持してファイルを閉じる

;-------------------------------------------------------------------------------

logo_load_rom128:                      ; IPLROM 128KB
    move.l  #$000112a8,d0              ; IPLROM内のロゴ先頭位置
    bra     logo_load_rom              ; ロゴデータを読み込む
logo_load_rom1024:                     ; FULLROM 1MB
    move.l  #$000f12a8,d0              ; FULLROM内のロゴ先頭位置

logo_load_rom:                         ; ROMイメージ内のロゴを読み込む
    clr.w   -(sp)                      ; ファイル先頭から
    move.l  d0,-(sp)                   ; ロゴ先頭までのオフセット
    move.w  logo_handle,-(sp)          ; ロゴファイルのハンドル
    DOS     _SEEK                      ; ロゴ位置まで移動する
    addq.l  #8,sp                      ; _SEEKの引数8バイトを取り除く
    or.l    d0,d0                      ; シークに成功したかな？
    bmi     logo_load_io_error         ; 負なら読み込みエラー

    move.l  #424,-(sp)                 ; FNTBUFの最大サイズだけ読み込む
    pea.l   logo_textbuffer            ; 入力データのバッファ
    move.w  logo_handle,-(sp)          ; ロゴファイルのハンドル
    DOS     _READ                      ; ROM内のロゴデータを取得
    lea.l   10(sp),sp                  ; _READの引数10バイトを取り除く
    cmpi.l  #424,d0                    ; 424バイトを読み込めたかな？
    bne     logo_load_io_error         ; 読み込み不足やエラーなら終了する

    lea.l   logo_textbuffer,a0         ; 取得したFNTBUF候補の先頭
    bsr     logo_check_fnt_header      ; 幅と高さ、必要なサイズを検査する
    tst.l   d0                         ; ロゴとして認識できたかな？
    bmi     logo_load_format_error     ; ロゴがなければ形式エラー
    move.w  d0,logo_length             ; FNTBUF全体の長さを保存する
    bsr     logo_copy_fnt              ; 必要な範囲だけロゴバッファへコピーする
    moveq   #0,d0                      ; 読み込み成功
    bra     logo_load_close            ; ロゴファイルを閉じる

;-------------------------------------------------------------------------------

logo_check_fnt_header:                 ; A0=ヘッダ先頭 / D0=必要なサイズ(異常時 -1)
    moveq   #0,d0                      ; 幅を符号なしワードとして取得するため初期化
    move.w  (a0),d0                    ; 先頭2バイトが横幅
    beq     logo_check_fnt_invalid     ; 横幅0ドットは受け付けない
    cmpi.w  #208,d0                    ; 16ドット高で424バイトに収まるかな？
    bhi     logo_check_fnt_invalid     ; 横幅208ドット超過はエラー
    cmpi.w  #16,2(a0)                  ; 縦幅はIPLROMの表示処理にあわせ16ドットかな？
    bne     logo_check_fnt_invalid     ; 16ドット以外は受け付けない
    move.w  d0,logo_width              ; 検証済みのロゴ幅を保存
    addq.l  #7,d0                      ; 端数があるときはバイト単位へ切り上げる
    lsr.l   #3,d0                      ; 1行あたりの必要バイト数
    lsl.l   #4,d0                      ; 16行分の画像データサイズ
    addq.l  #4,d0                      ; 先頭の幅・高さ4バイトを加算
    rts                                ; バッファの必要サイズを返す
logo_check_fnt_invalid:                ; FNTBUFヘッダの検証失敗
    moveq   #-1,d0                     ; ヘッダが不正
    rts                                ; エラー値を呼び出し元へ返す

logo_copy_fnt:                         ; A0=コピー元 / logo_length=コピーする長さ
    lea.l   logo_buffer,a1             ; コピー先のFNTBUFバッファ
    move.w  logo_length,d6             ; コピーするバイト数
    subq.w  #1,d6                      ; DBRAで指定回数だけコピーする
@@:                                    ; FNTBUFデータのコピーを繰り返す
    move.b  (a0)+,(a1)+                ; FNTBUFを先頭から1バイトずつコピー
    dbra    d6,@b                      ; 指定バイト数をコピーするまで繰り返す
    rts                                ; FNTBUFのコピー完了

;-------------------------------------------------------------------------------

logo_parse_text:                       ; #=点灯 / .=消灯 のテキストからFNTBUFを生成
    lea.l   logo_buffer,a1             ; データ初期化先
    move.w  #105,d0                    ; 424バイトをロングワード106個として扱う
@@:                                    ; FNTBUFバッファ全体を初期化する
    clr.l   (a1)+                      ; 未使用のビットを含めロゴバッファを初期化
    dbra    d0,@b                      ; 全域を初期化する

    lea.l   logo_textbuffer,a0         ; 先頭からテキストを読み取る
    lea.l   logo_buffer+4,a1           ; ヘッダ4バイトの後が画素データ
    move.l  logo_filesize,d2           ; 残りの読み取りバイト数
    clr.w   d4                         ; 現在行の横幅(文字数)
    clr.w   d5                         ; 読み込み済みの行数
    moveq   #7,d6                      ; 1バイトの最上位ビットから格納する
    moveq   #0,d7                      ; 1バイト分の画素を蓄積する

logo_text_next:                        ; テキストを1文字ずつ解析する
    tst.l   d2                         ; まだ文字が残っているかな？
    beq     logo_text_eof              ; 末尾なら最後の行を確定する
    moveq   #0,d0                      ; 文字を符号なしバイトで取得する
    move.b  (a0)+,d0                   ; テキストの1文字を取得
    subq.l  #1,d2                      ; 残りの文字数を減らす
    cmpi.b  #'#',d0                    ; 点灯ピクセルかな？
    beq     logo_text_pixel_on         ; ビットを立てる処理へ
    cmpi.b  #'.',d0                    ; 消灯ピクセルかな？
    beq     logo_text_pixel_off        ; ビットを進める処理へ
    cmpi.b  #$0d,d0                    ; CR改行かな？
    beq     logo_text_cr               ; CRLFかCRかを判別する
    cmpi.b  #$0a,d0                    ; LF改行かな？
    beq     logo_text_newline          ; 行の終わりとして扱う
    bra     logo_text_error_char       ; それ以外の文字は受け付けない

logo_text_pixel_on:                    ; 点灯ピクセルを1ビットとして設定する
    cmpi.w  #16,d5                     ; 17行目以降のデータかな？
    bhs     logo_text_error_height     ; 行数超過ならエラー
    cmpi.w  #208,d4                    ; 209文字目以降かな？
    bhs     logo_text_error_size       ; 最大横幅を超えるのでエラー
    bset    d6,d7                      ; 点灯ピクセルのビットを1にする
    bra     logo_text_pixel_store      ; ビット位置を進める

logo_text_pixel_off:                   ; 消灯ピクセルの位置を進める
    cmpi.w  #16,d5                     ; 17行目以降のデータかな？
    bhs     logo_text_error_height     ; 行数超過ならエラー
    cmpi.w  #208,d4                    ; 209文字目以降かな？
    bhs     logo_text_error_size       ; 最大横幅を超えるのでエラー

logo_text_pixel_store:                 ; ピクセルの格納位置を次へ進める
    addq.w  #1,d4                      ; 現在行の文字数を1増やす
    subq.w  #1,d6                      ; 次のピクセルを格納するビット位置
    bpl     logo_text_next             ; まだ1バイトに満たないので次の文字へ
    move.b  d7,(a1)+                   ; 8ドット分を1バイトとして書き込む
    moveq   #0,d7                      ; 次のバイトのために初期化する
    moveq   #7,d6                      ; 次のバイトも最上位ビットから始める
    bra     logo_text_next             ; 次の文字へ

logo_text_cr:                          ; CR改行とCRLF改行を区別する
    tst.l   d2                         ; CRのあとにまだ文字があるかな？
    beq     logo_text_newline          ; 末尾ならCRのみの改行とみなす
    cmpi.b  #$0a,(a0)                  ; 次の文字がLFかな？
    bne     logo_text_newline          ; LFじゃなければCR単独の改行
    addq.l  #1,a0                      ; CRLFのLFを読み飛ばす
    subq.l  #1,d2                      ; 読み飛ばした1バイトを減算する

logo_text_newline:                     ; 1行分の画素データを確定する
    bsr     logo_text_end_row          ; 1行の文字数と画像データを確定する
    tst.l   d0                         ; 行の検証は成功したかな？
    bmi     logo_text_return           ; 失敗ならエラー情報を返す
    bra     logo_text_next             ; 次の行へ

logo_text_eof:                         ; 入力ファイルの末尾を処理する
    tst.w   d4                         ; 最後の行にデータが残っているかな？
    beq     logo_text_end_check        ; 末尾が改行なら行数を確認する
    bsr     logo_text_end_row          ; 改行がない最後の行を確定する
    tst.l   d0                         ; 最終行の検証は成功したかな？
    bmi     logo_text_return           ; 失敗ならエラー情報を返す

logo_text_end_check:                   ; 行数を検査してFNTBUFを完成する
    cmpi.w  #16,d5                     ; ロゴは全部で16行かな？
    bne     logo_text_error_height     ; 行数不足や超過ならエラー
    move.w  logo_width,d0              ; 横幅を取得する
    addq.w  #7,d0                      ; 端数を8ドット単位に切り上げる
    lsr.w   #3,d0                      ; 1行分のバイト数
    lsl.w   #4,d0                      ; 全16行のバイト数
    addq.w  #4,d0                      ; FNTBUFのヘッダ4バイトを加算
    move.w  d0,logo_length             ; 完成したデータ長を保存
    move.w  logo_width,logo_buffer     ; FNTBUFの先頭2バイトに横幅を設定
    move.w  #16,logo_buffer+2          ; 次の2バイトに高さ16を設定
    moveq   #0,d0                      ; テキストの変換完了
logo_text_return:                      ; テキスト変換の結果を返す
    rts                                ; 変換結果を呼び出し元へ返す

logo_text_end_row:                     ; D4=行の幅 / D5=終了済み行数
    tst.w   d4                         ; 空行かな？
    beq     logo_text_error_width      ; 空行は受け付けない
    tst.w   d5                         ; 先頭行かな？
    bne     @f                         ; 先頭行じゃないので横幅を比較する
    move.w  d4,logo_width              ; 先頭行の文字数をロゴ幅として保存する
    bra     logo_text_row_flush        ; 次の処理へ
@@:                                    ; 2行目以降の横幅を先頭行と比較する
    cmp.w   logo_width,d4              ; ほかの行と文字数が一致するかな？
    bne     logo_text_error_width      ; 異なる行は受け付けない

logo_text_row_flush:                   ; 行末に残った画素を1バイトにまとめる
    cmpi.w  #7,d6                      ; 途中まで書き込んだバイトがあるかな？
    beq     @f                         ; ないのでそのまま次の行へ
    move.b  d7,(a1)+                   ; 8ドット未満の行末もバイトとして書き込む
@@:                                    ; 行末データの確定を完了する
    addq.w  #1,d5                      ; 終了した行の数を増やす
    clr.w   d4                         ; 次の行の文字数を0から数える
    moveq   #0,d7                      ; 次の行のビット列を初期化する
    moveq   #7,d6                      ; 次の行も最上位ビットから書き込む
    moveq   #0,d0                      ; 1行の検証と確定が成功した
    rts                                ; 次の行へ進むため呼び出し元へ戻る

logo_text_error_char:                  ; テキストの文字種エラー
    moveq   #-5,d0                     ; 使用禁止文字が見つかった
    bra     logo_text_set_error_pos    ; 行と文字位置を記録する
logo_text_error_width:                 ; テキストの行幅または空行エラー
    moveq   #-6,d0                     ; 行の文字数が一致しない、または空行
    bra     logo_text_set_error_pos    ; 行を記録する
logo_text_error_height:                ; テキストの行数エラー
    moveq   #-7,d0                     ; 16行ではない
    bra     logo_text_set_error_pos    ; 行を記録する
logo_text_error_size:                  ; テキストの最大横幅超過エラー
    moveq   #-4,d0                     ; 横幅208ドット超過
logo_text_set_error_pos:               ; エラーになった行と文字位置を記録する
    move.w  d5,logo_error_line         ; 終了済み行数が現在行の0始まり番号
    addq.w  #1,logo_error_line         ; 表示用に1始まりの行番号にする
    move.w  d4,logo_error_col          ; 行内で読み込んだ文字数
    addq.w  #1,logo_error_col          ; 表示用に1始まりの文字位置にする
    rts                                ; 呼び出し元へエラーを返す

;-------------------------------------------------------------------------------

logo_load_open_error:                  ; ロゴファイルを開けなかった場合
    moveq   #-1,d0                     ; ロゴファイルを開けなかった
    rts                                ; ハンドルがないのでそのまま戻る
logo_load_io_error:                    ; ロゴファイルの読み込みに失敗した場合
    moveq   #-2,d0                     ; ロゴファイル読み込みエラー
    bra     logo_load_close            ; 開いているファイルを閉じる
logo_load_format_error:                ; ロゴ形式の検証に失敗した場合
    moveq   #-3,d0                     ; ファイル形式が不正
    bra     logo_load_close            ; 開いているファイルを閉じる
logo_load_size_error:                  ; ロゴデータが最大サイズを超えた場合
    moveq   #-4,d0                     ; データサイズが上限を超えている

logo_load_close:                       ; ロゴファイルを閉じる共通処理
    move.l  d0,logo_result             ; _CLOSEでD0が変わるので検証結果を保存
    move.w  logo_handle,-(sp)          ; ロゴファイルのハンドル
    DOS     _CLOSE                     ; ロゴファイルを閉じる
    addq.l  #2,sp                      ; _CLOSEの引数2バイトを取り除く
    move.l  logo_result,d0             ; 検証結果を復元する
    rts                                ; 検証結果を呼び出し元へ返す

;===============================================================================
;
; ロゴファイルのエラー表示
;  行番号・文字位置はテキストの読み取り時に保存してある
;
;===============================================================================

logo_error:                            ; ロゴ読み込みのエラー種別を振り分ける
    cmpi.l  #-1,d0                     ; ファイルを開けなかったかな？
    beq     logo_error_open            ; オープンエラーのメッセージへ
    cmpi.l  #-2,d0                     ; 読み込みに失敗したかな？
    beq     logo_error_read            ; 読み込みエラーのメッセージへ
    cmpi.l  #-3,d0                     ; ファイル形式が不正かな？
    beq     logo_error_format          ; 形式エラーのメッセージへ
    cmpi.l  #-4,d0                     ; 最大サイズを超えたかな？
    beq     logo_error_size            ; サイズエラーのメッセージへ
    cmpi.l  #-5,d0                     ; テキストに不正な文字があったかな？
    beq     logo_error_char            ; 文字エラーのメッセージへ
    cmpi.l  #-6,d0                     ; 行の文字数が不一致だったかな？
    beq     logo_error_width           ; 横幅エラーのメッセージへ
    bra     logo_error_height          ; 16行以外は行数エラーとして表示する

logo_error_open:                       ; ファイルオープンエラーを表示する
    pea.l   mes_logo_open_error        ; 外部ロゴファイルを開けない
    bra     logo_error_print           ; メッセージを表示して終了する
logo_error_read:                       ; ファイル読み込みエラーを表示する
    pea.l   mes_logo_read_error        ; 外部ロゴファイルを読み込めない
    bra     logo_error_print           ; メッセージを表示して終了する
logo_error_format:                     ; ファイル形式エラーを表示する
    pea.l   mes_logo_format_error      ; 形式が違う
    bra     logo_error_print           ; メッセージを表示して終了する
logo_error_size:                       ; ファイルサイズエラーを表示する
    pea.l   mes_logo_size_error        ; データサイズが大きすぎる
    bra     logo_error_print           ; メッセージを表示して終了する

logo_error_char:                       ; テキストの文字種エラーを表示する
    pea.l   mes_logo_char_error        ; 不正な文字
    bra     logo_error_location        ; 行と文字位置を添えて表示する
logo_error_width:                      ; テキストの行幅エラーを表示する
    pea.l   mes_logo_width_error       ; 行の文字数が一致しない
    bra     logo_error_location        ; 行番号を添えて表示する
logo_error_height:                     ; テキストの行数エラーを表示する
    pea.l   mes_logo_height_error      ; 行数が16ではない

logo_error_location:                   ; エラー位置の行番号と文字位置を表示する
    DOS     _PRINT                     ; 原因を先に表示する
    addq.l  #4,sp                      ; _PRINTの引数4バイトを取り除く
    pea.l   mes_logo_line              ; 行番号の前文
    DOS     _PRINT                     ; 行番号の表示文を出力する
    addq.l  #4,sp                      ; _PRINTの引数4バイトを取り除く
    moveq   #0,d0                      ; 行番号を符号なしで表示する
    move.w  logo_error_line,d0         ; エラー行番号を取得
    bsr     logo_print_decimal         ; 行番号を10進数で表示
    pea.l   mes_logo_column            ; 文字位置の前文
    DOS     _PRINT                     ; 文字位置の表示文を出力する
    addq.l  #4,sp                      ; _PRINTの引数4バイトを取り除く
    moveq   #0,d0                      ; 文字位置を符号なしで表示する
    move.w  logo_error_col,d0          ; エラー文字位置を取得
    bsr     logo_print_decimal         ; 文字位置を10進数で表示
    pea.l   mes_logo_end               ; エラー位置の後文
    bra     logo_error_print           ; メッセージを閉じて終了する

logo_error_print:                      ; エラーメッセージを表示して終了する
    DOS     _PRINT                     ; エラーメッセージを表示する
    addq.l  #4,sp                      ; _PRINTの引数4バイトを取り除く
    DOS     _EXIT                      ; 対象ROMを書き換えずに終了する

;-------------------------------------------------------------------------------

logo_print_decimal:                    ; D0(0～999)を10進数で表示する
    movem.l d1-d2,-(sp)                ; 使用するレジスタを保存する
    moveq   #0,d1                      ; DIVUの被除数を32ビットで用意する
    move.w  d0,d1                      ; 10進数に変換する値
    divu.w  #100,d1                    ; 百の位と下二桁に分割する
    move.w  d1,d2                      ; 百の位を保存する
    tst.w   d2                         ; 百の位は0かな？
    beq     @f                         ; 0なら先頭のゼロを省略する
    move.w  d2,d0                      ; 百の位を表示する
    bsr     logo_print_digit           ; 百の位を1桁表示する
@@:                                    ; 残りの桁を処理する
    swap    d1                         ; 下二桁を下位ワードへ移す
    andi.l  #$0000ffff,d1              ; 上位ワードを0にしてDIVUの桁あふれを防ぐ
    divu.w  #10,d1                     ; 十の位と一の位に分割する
    move.w  d1,d0                      ; 十の位
    tst.w   d2                         ; 百の位を表示したかな？
    bne     @f                         ; 表示済みなら十の位も必ず表示する
    tst.w   d0                         ; 十の位は0かな？
    beq     logo_print_decimal_ones    ; 0なら一の位のみ表示する
@@:                                    ; 十の位を表示する
    bsr     logo_print_digit           ; 十の位を表示する
logo_print_decimal_ones:               ; 一の位を表示する
    swap    d1                         ; 一の位を下位ワードへ移す
    move.w  d1,d0                      ; 一の位
    bsr     logo_print_digit           ; 一の位を表示する
    movem.l (sp)+,d1-d2                ; 保存していたレジスタを復元する
    rts                                ; 10進数の表示処理を終了する

logo_print_digit:                      ; 0～9の数値をASCII文字で表示する
    addi.w  #'0',d0                    ; 0～9を文字コードにする
    move.w  d0,-(sp)                   ; 表示する文字
    DOS     _PUTCHAR                   ; 数値を1文字表示する
    addq.l  #2,sp                      ; _PUTCHARの引数2バイトを取り除く
    rts                                ; 数値1桁の表示処理を終了する

;===============================================================================

print_emulatorcode:                    ; ｴﾐｭﾚｰﾀｺｰﾄﾞ表示
    bsr     printb

    pea.l   mes_emulatorcode2
    DOS     _PRINT
    addq.l  #4,sp

    move.b  emulatorcode,d0            ; 機種ｺｰﾄﾞ
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
logo_builtin:                          ; X680x0の内蔵ロゴ(FNTBUF 112×16ドット / 228バイト)
    .dc.b   $00,$70,$00,$10,$03,$ff    ; 内蔵ロゴのFNTBUFデータ (1～6バイト目)
    .dc.b   $f9,$ff,$e0,$00,$00,$00    ; 内蔵ロゴのFNTBUFデータ (7～12バイト目)
    .dc.b   $08,$00,$00,$00,$00,$00    ; 内蔵ロゴのFNTBUFデータ (13～18バイト目)
    .dc.b   $01,$80,$0c,$c0,$c0,$ff    ; 内蔵ロゴのFNTBUFデータ (19～24バイト目)
    .dc.b   $83,$fe,$08,$1f,$f0,$00    ; 内蔵ロゴのFNTBUFデータ (25～30バイト目)
    .dc.b   $07,$fc,$01,$80,$0c,$c1    ; 内蔵ロゴのFNTBUFデータ (31～36バイト目)
    .dc.b   $83,$ff,$cf,$ff,$08,$7f    ; 内蔵ロゴのFNTBUFデータ (37～42バイト目)
    .dc.b   $f8,$00,$1f,$fe,$00,$c0    ; 内蔵ロゴのFNTBUFデータ (43～48バイト目)
    .dc.b   $06,$63,$07,$01,$dc,$07    ; 内蔵ロゴのFNTBUFデータ (49～54バイト目)
    .dc.b   $10,$e0,$38,$00,$38,$0e    ; 内蔵ロゴのFNTBUFデータ (55～60バイト目)
    .dc.b   $00,$c0,$06,$66,$06,$01    ; 内蔵ロゴのFNTBUFデータ (61～66バイト目)
    .dc.b   $d8,$03,$10,$c0,$18,$00    ; 内蔵ロゴのFNTBUFデータ (67～72バイト目)
    .dc.b   $30,$06,$00,$60,$03,$3c    ; 内蔵ロゴのFNTBUFデータ (73～78バイト目)
    .dc.b   $06,$00,$1c,$06,$32,$c0    ; 内蔵ロゴのFNTBUFデータ (79～84バイト目)
    .dc.b   $1b,$87,$30,$06,$00,$60    ; 内蔵ロゴのFNTBUFデータ (85～90バイト目)
    .dc.b   $03,$38,$0f,$ff,$1f,$fe    ; 内蔵ロゴのFNTBUFデータ (91～96バイト目)
    .dc.b   $35,$80,$31,$ce,$60,$0c    ; 内蔵ロゴのFNTBUFデータ (97～102バイト目)
    .dc.b   $00,$30,$01,$90,$0f,$ff    ; 内蔵ロゴのFNTBUFデータ (103～108バイト目)
    .dc.b   $9f,$fc,$79,$80,$30,$dc    ; 内蔵ロゴのFNTBUFデータ (109～114バイト目)
    .dc.b   $60,$0c,$01,$30,$01,$80    ; 内蔵ロゴのFNTBUFデータ (115～120バイト目)
    .dc.b   $0c,$03,$b8,$1e,$79,$80    ; 内蔵ロゴのFNTBUFデータ (121～126バイト目)
    .dc.b   $30,$f8,$60,$0c,$03,$98    ; 内蔵ロゴのFNTBUFデータ (127～132バイト目)
    .dc.b   $00,$c0,$18,$01,$b0,$0e    ; 内蔵ロゴのFNTBUFデータ (133～138バイト目)
    .dc.b   $b1,$80,$30,$70,$40,$0c    ; 内蔵ロゴのFNTBUFデータ (139～144バイト目)
    .dc.b   $07,$98,$00,$c0,$18,$03    ; 内蔵ロゴのFNTBUFデータ (145～150バイト目)
    .dc.b   $60,$0d,$33,$00,$60,$f0    ; 内蔵ロゴのFNTBUFデータ (151～156バイト目)
    .dc.b   $c0,$18,$0c,$cc,$00,$60    ; 内蔵ロゴのFNTBUFデータ (157～162バイト目)
    .dc.b   $18,$03,$60,$0c,$23,$00    ; 内蔵ロゴのFNTBUFデータ (163～168バイト目)
    .dc.b   $61,$f0,$c0,$18,$18,$cc    ; 内蔵ロゴのFNTBUFデータ (169～174バイト目)
    .dc.b   $00,$60,$1c,$07,$70,$1c    ; 内蔵ロゴのFNTBUFデータ (175～180バイト目)
    .dc.b   $23,$80,$e3,$b8,$e0,$38    ; 内蔵ロゴのFNTBUFデータ (181～186バイト目)
    .dc.b   $30,$66,$00,$30,$1f,$fe    ; 内蔵ロゴのFNTBUFデータ (187～192バイト目)
    .dc.b   $7f,$f8,$43,$ff,$c7,$18    ; 内蔵ロゴのFNTBUFデータ (193～198バイト目)
    .dc.b   $ff,$f0,$60,$66,$00,$30    ; 内蔵ロゴのFNTBUFデータ (199～204バイト目)
    .dc.b   $0f,$f8,$3f,$e0,$41,$ff    ; 内蔵ロゴのFNTBUFデータ (205～210バイト目)
    .dc.b   $8e,$1c,$7f,$c0,$ff,$f3    ; 内蔵ロゴのFNTBUFデータ (211～216バイト目)
    .dc.b   $ff,$f8,$00,$00,$00,$00    ; 内蔵ロゴのFNTBUFデータ (217～222バイト目)
    .dc.b   $40,$00,$00,$00,$00,$00    ; 内蔵ロゴのFNTBUFデータ (223～228バイト目)
logo_series_crlf:                      ; 拡張ロゴ用のSERIES非表示パターン
    .dc.b   $0d,$0a,$00                ; ロゴ拡張時にSERIES表示を消す
logo_series_spaces:                    ; SERIES表示を元に戻すための空白パターン
    .dc.b   $20,$20,$20                ; 標準幅へ戻したときのSERIES表示を復元する

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
flag_FULLROM:
    .ds.b   1
;-------------------------------------------------------------------------------
logo_handle:                           ; 外部ロゴファイルのハンドル
    .ds.w   1                          ; 入力ロゴファイルのハンドル
logo_length:                           ; 検証済みFNTBUFのバイト数
    .ds.w   1                          ; FNTBUFのデータ長(最大424バイト)
logo_width:                            ; 検証済みロゴの横幅
    .ds.w   1                          ; ロゴの横幅(最大208ドット)
logo_error_line:                       ; テキストエラーの行番号
    .ds.w   1                          ; テキストエラーの行番号
logo_error_col:                        ; テキストエラーの文字位置
    .ds.w   1                          ; テキストエラーの文字位置
logo_filesize:                         ; 外部ロゴファイル全体のバイト数
    .ds.l   1                          ; 入力ファイル全体のサイズ
logo_result:                           ; ファイルクローズ後に返す検証結果
    .ds.l   1                          ; _CLOSEをまたぐ検証結果
logo_series_check:                     ; SERIES表示位置の3バイトを検査する領域
    .ds.b   4                          ; 現在のSERIES表示設定を確認する
logo_filename:                         ; 外部ロゴファイル名の格納領域
    .ds.b   256                        ; -x= で指定されたロゴファイル名
    .even                              ; 次のデータ領域を偶数アドレスに揃える
logo_buffer:                           ; FNTBUFを組み立てる作業領域
    .ds.b   424                        ; 書き込むFNTBUF(ヘッダ4バイトを含む)
logo_textbuffer:                       ; ロゴファイルの読み込み作業領域
    .ds.b   3360                       ; 208文字×16行×CRLF込みの最大サイズ
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
mes_logo_file_patched:                 ; 外部ロゴの適用完了メッセージ
    .dc.b   '指定されたファイルの起動ロゴを設定しました！',$0d,$0a,00
mes_logo_open_error:                   ; ロゴファイルオープン失敗のメッセージ
    .dc.b   'ロゴファイルを開けませんでした(TдT)',$0d,$0a,$0d,$0a,0
mes_logo_read_error:                   ; ロゴファイル読み込み失敗のメッセージ
    .dc.b   'ロゴファイルを読み込めませんでした(TдT)',$0d,$0a,$0d,$0a,0
mes_logo_format_error:                 ; FNTBUF/ROM/TXT判定失敗のメッセージ
    .dc.b   'ご指定のファイルはロゴ形式ではありません(TдT)',$0d,$0a,$0d,$0a,0
mes_logo_size_error:                   ; ロゴサイズ超過のメッセージ
    .dc.b   'ロゴのサイズが上限を超えています(TдT)',$0d,$0a,$0d,$0a,0
mes_logo_char_error:                   ; テキストに不正な文字があるときのメッセージ
    .dc.b   'ロゴのテキストに使えない文字があります！',0
mes_logo_width_error:                  ; 行幅不一致または空行のメッセージ
    .dc.b   'ロゴの行ごとの文字数が違うか、空行があります！',0
mes_logo_height_error:                 ; 行数が16でないときのメッセージ
    .dc.b   'ロゴのテキストは16行にしてください！',0
mes_logo_line:                         ; エラー位置の前に付ける文字列
    .dc.b   ' [',0
mes_logo_column:                       ; エラー行と文字位置の区切り
    .dc.b   '行 ',0
mes_logo_end:                          ; エラー位置の後ろに付ける文字列
    .dc.b   '文字目] (TдT)',$0d,$0a,$0d,$0a,0
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
    .dc.b   $f3,'v',$f3,'e',$f3,'r',$f3,'s',$f3,'i',$f3,'o',$f3,'n',$f3,' ',$f3,'1',$f3,'.',$f3,'2',$f3,'7',$00
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
    .dc.b   '   -x=logo_file   : ロゴファイル(DAT/ROM/TXT)から設定します',$0d,$0a
    .dc.b   '   -h             : ヘルプを表示します',$0d,$0a
    .dc.b   ' [filename]',$0d,$0a
    .dc.b   '  パッチをあてる IPLROM ($fe0000-$ffffff) または',$0d,$0a
    .dc.b   '  FULLROM ($f00000-$ffffff) のダンプファイルです',$0d,$0a
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
