# Run this after opencc autoconversion, sed script shoule be run in this order:
# doc content substitution
s/簡體/繁體/g
s/maint-guide-zh-cn/maint-guide-zh-tw/g
# opencc bug work around
s/在綫/在線/g
s/發布里/發佈裏/g
s/綫索/線索/g
s/裏麵/裡面/g
# idiom conversion
# Left:  string auto-converted from zh_CN to zh_TW with opencc
# Right: better string to use under zh_TW
# manually sorted list with longer one first etc.
s/軟件包/套件/g
s/軟件/軟體/g
s/二進制包/二進位套件/g
s/二進制/二進位/g
s/源代碼包/原始碼套件/g
s/源代碼/原始碼/g
s/歸檔文件/壓縮檔/g
s/文件/檔案/g
s/文檔/文件/g
s/內核模塊/核心模組/g
s/內核補丁/核心補丁/g
s/內核/核心/g
# auto sorted list "sort"
s/下劃綫/底線/g
s/主頁/首頁/g
s/代碼/程式碼/g
s/信息/訊息/g
s/分發/散佈/g
s/刷新/更新/g
s/半角/半形/g
s/卸載/反安裝/g
s/參看/參考/g
s/圖標/圖示/g
s/屏幕/螢幕/g
s/操作系統/作業系統/g
s/擴展名/副檔名/g
s/數字簽名/數位簽章/g
s/示例/範例/g
s/社區/社群/g
s/程序/程式/g
s/老板本/舊版本/g
s/自檢/自身測試/g
s/解包/解壓縮/g
s/解釋型/解譯型/g
s/配置/設定/g
# One character ones which needs to be careful
s/棧/堆疊/g
s/宏/巨集/g
# Special exclusion rules
s/\([^區]\)域/\1欄位/g
s/\([^倉]\)庫/\1函式庫/g
# formatting fix only for maint-guide table
s/3        函數函式庫調用        系統函式庫提供的函數/3        函數函式庫調用     系統函式庫提供的函數/
s/7        巨集包             例如 man 巨集/7        巨集包            例如 man 巨集/

