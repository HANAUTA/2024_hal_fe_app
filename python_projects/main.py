from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
import time
import csv
import gspread
from google.oauth2.service_account import Credentials
from dotenv import load_dotenv
import os


SPREAD_SHEET_ID = os.getenv("SPREAD_SHEET_ID")

mondai_datas = []
category_name = {"ストラテジ系": "strategyStage", "テクノロジ系": "technologyStage", "マネジメント系": "managementStage"}
kotae_dict = {"ア": "lia", "イ": "lii", "ウ": "liu", "エ": "lie"}
kotae_dict_sentakusi = {"ア": "select_a", "イ": "select_i", "ウ": "select_u", "エ": "select_e"}
kotae_dict_sentakusi_r = {"select_a": "ア", "select_i": "イ", "select_u": "ウ", "select_e": "エ"}
# 年度 候補
"""
05_menjo
04_menjo
03_menjo
02_menjo
01_aki
31_haru
30_aki
30_haru
29_aki
29_haru
28_aki
28_haru
27_aki
27_haru
26_aki
26_haru
25_aki
25_haru
24_aki
24_haru
23_aki
23_haru
22_aki
22_haru
21_aki
21_haru
20_aki
20_haru
"""
TARGET_NENDO = "05_menjo"
LOOP_TIMES = 60

series_num = {
  "基礎理論": "1001",
  "アルゴリズムとプログラミング": "1002",
  "コンピュータ構成要素": "1003",
  "システム構成要素": "1004",
  "ソフトウェア": "1005",
  "ハードウェア": "1006",
  "ヒューマンインターフェース": "1007",
  "マルチメディア": "1008",
  "情報メディア": "1008",
  "データベース": "1009",
  "ネットワーク": "1010",
  "セキュリティ": "1011",
  "システム開発技術": "1012",
  "ソフトウェア開発管理技術": "1013",
  "プロジェクトマネジメント": "2001",
  "サービスマネジメント": "2002",
  "システム監査": "2003",
  "システム戦略": "3001",
  "システム企画": "3002",
  "経営戦略マネジメント": "3003",
  "技術戦略マネジメント": "3004",
  "ビジネスインダストリ": "3005",
  "企業活動": "3006",
  "法務": "3007"
}

series_reigai = {
    "情報メディア": "マルチメディア",
    "ユーザーインタフェース": "ヒューマンインターフェース",
}

stage_num = {
    "離散数学": "1001001",
    "応用数学": "1001002",
    "情報理論": "1001003",
    "情報に関する理論": "1001003",
    "通信理論": "1001004",
    "通信に関する理論": "1001004",
    "計測制御理論": "1001005",
    "計測・制御に関する理論": "1001005",
    
    "データ構造": "1002001",
    "アルゴリズム": "1002002",
    "プログラミング": "1002003",
    "プログラム言語": "1002004",
    "マークアップ言語など": "1002005",
    
    "プロセッサ": "1003001",
    "メモリ": "1003002",
    "バス": "1003003",
    "入出力デバイス": "1003004",
    "入出力装置": "1003005",
    
    "システムの構成": "1004001",
    "システム評価指標": "1004002",
    "システムの評価指標": "1004002",
    
    "オペレーティングシステム": "1005001",
    "ミドルウェア": "1005002",
    "ファイルシステム": "1005003",
    "開発ツール": "1005004",
    "オープンソースソフトウェア": "1005005",
    
    "ハードウェア全般": "1006001",
    "ハードウェア": "1006001",
    
    "ヒューマンインターフェイス技術": "1007001",
    "ユーザーインタフェース技術": "1007001",
    "UX/UIデザイン": "1007001",
    "インターフェイス設計": "1007002",
    
    "マルチメディア技術": "1008001",
    "マルチメディア応用": "1008002",
    
    "データベース方式": "1009001",
    "データベース設計": "1009002",
    "データ操作": "1009003",
    "トランザクション処理": "1009004",
    "データベース応用": "1009005",
    
    "ネットワーク方式": "1010001",
    "データ通信と制御": "1010002",
    "通信プロトコル": "1010003",
    "ネットワーク管理": "1010004",
    "ネットワーク応用": "1010005",
    
    "情報セキュリティ": "1011001",
    "情報セキュリティ管理": "1011002",
    "セキュリティ技術評価": "1011003",
    "情報セキュリティ対策": "1011004",
    "セキュリティ実装技術": "1011005",
    
    "システム要件定義／ソフトウェア要件定義": "1012001",
    "システム要件定義": "1012001",
    "ソフトウェア要件定義": "1012001",
    "設計": "1012002",
    "ソフトウェア方式設計・詳細設計": "1012002",
    "実装／構築": "1012003",
    "ソフトウェア構築": "1012003",
    "結合／テスト": "1012004",
    "ソフトウェア結合・適格性テスト": "1012004",
    "導入／受入支援": "1012005",
    "保守／廃棄": "1012006",
    "保守・廃棄": "1012006",
    
    "開発プロセス・手法": "1013001",
    "知的財産適用管理": "1013002",
    "開発環境管理": "1013003",
    "構成管理／変更管理": "1013004",
    
    "プロジェクトマネジメント": "2001001",
    "プロジェクトの統合": "2001002",
    "プロジェクトのステークホルダ": "2001003",
    "プロジェクトのスコープ": "2001004",
    "プロジェクトの資源": "2001005",
    "プロジェクトの時間": "2001006",
    "プロジェクトのコスト": "2001007",
    "プロジェクトのリスク": "2001008",
    "プロジェクトの品質": "2001009",
    "プロジェクトの調達": "2001010",
    "プロジェクトのコミュニケーション": "2001011",
    
    "サービスマネジメント": "2002001",
    "サービスマネジメントシステムの計画及び運用": "2002002",
    "サービスの設計・移行": "2002002",
    "サービスマネジメントプロセス": "2002002",
    "パフォーマンス評価及び改善": "2002003",
    "サービスの運用": "2002004",
    "ファシリティマネジメント": "2002005",
    
    "システム監査": "2003001",
    "内部統制": "2003002",
    
    "情報システム戦略": "3001001",
    "業務プロセス": "3001002",
    "ソリューションビジネス": "3001003",
    "システム活用促進評価": "3001004",
    "システム活用促進・評価": "3001004",
    
    "システム化計画": "3002001",
    "要件定義": "3002002",
    "調達計画／実施": "3002003",
    "調達計画・実施": "3002003",
    
    "経営戦略手法": "3003001",
    "マーケティング": "3003002",
    "ビジネス戦略と目標・評価": "3003003",
    "経営管理システム": "3003004",
    
    "技術開発戦略の立案": "3004001",
    "技術開発計画": "3004002",
    
    "ビジネスシステム": "3005001",
    "エンジニアリングシステム": "3005002",
    "e-ビジネス": "3005003",
    "民生機器": "3005004",
    "産業機器": "3005005",
    
    "経営組織論": "3006001",
    "経営・組織論": "3006001",
    "OR／IE": "3006002",
    "業務分析・データ利活用": "3006002",
    "会計財務": "3006003",
    "会計・財務": "3006003",
    
    "知的財産権": "3007001",
    "セキュリティ関連法規": "3007002",
    "労働関連/取引関連法規": "3007003",
    "労働関連・取引関連法規": "3007003",
    "その他の法律／ガイドライン／技術者倫理": "3007004",
    "その他の法律・ガイドライン": "3007004",
    "標準化関連": "3007005"
}



# for debug
skip_count = 0

# オプション設定
chrome_options = Options()
chrome_options.add_experimental_option("detach", True)

# Chromeドライバーの自動設定
service = Service(ChromeDriverManager().install())
# backgroundで動かす
# chrome_options.add_argument('--headless')
driver = webdriver.Chrome(service=service, options=chrome_options)

# 対象のURLにアクセス
driver.get('https://www.fe-siken.com/fekakomon.php')

# --- 1. 'check_all_wrap'クラスの中で「OFF」というテキストがあるボタンをクリック ---
# 'check_all_wrap'クラスのdivを探す
check_all_wrap_div = driver.find_element(By.CLASS_NAME, 'check_all_wrap')

# div内の全てのボタンを取得
buttons = check_all_wrap_div.find_elements(By.TAG_NAME, 'button')

# ボタンのテキストが「OFF」のものをクリック
for button in buttons:
    if button.text == 'OFF':
        button.click()
        break

# 少し待機（次の操作に備えて）
time.sleep(0.2)

# --- 2. 'tab1'のidを持つdiv内の、'target_nendo'のvalueを持つinputをクリック ---
# 'tab1'のidを持つdivを探す
tab1_div = driver.find_element(By.ID, 'tab1')

# 'target_nendo'のvalueを持つinputを探す
menjo_input = tab1_div.find_element(By.CSS_SELECTOR, f'input[value="{TARGET_NENDO}"]')

# inputをクリック
menjo_input.click()

# 少し待機（次の操作に備えて）
time.sleep(0.2)

# --- 3. XPathを使って指定されたボタンをクリック ---
# 指定されたXPathのボタンをクリック
submit_button = driver.find_element(By.XPATH, '/html/body/div[1]/div/main/div[2]/form/div[2]/button')

# ボタンをクリック
submit_button.click()

# 少し待機して処理が完了するまで待つ
time.sleep(0.2)

cnt = 0

def get_mondai_bun(mondai_main):
    # 問題文を取得
    if cnt >= 1:
        mondai_bun = driver.find_element(By.XPATH, '/html/body/div[1]/div/main/div[2]/div[2]')
    else:
        mondai_bun = driver.find_element(By.XPATH, '/html/body/div[1]/div/main/div[2]/div[1]')

    return mondai_bun.text
    
def get_mondai_nendo(mondai_main):
    # 問題年度を取得
    mondai_nendo = mondai_main.find_element(By.CLASS_NAME, 'anslink').text
    mondai_nendo = mondai_nendo.split('\n')[0]

    return mondai_nendo

def get_mondai_category(mondai_main):
    # 問題カテゴリを取得
    mondai_category = mondai_main.find_element(By.TAG_NAME, 'p').text

    category = mondai_category.split('»')[0].strip()
    category = category_name[category]

    series = mondai_category.split('»')[1].strip()
    stage = mondai_category.split('»')[2].strip()    

    return [category, series, stage]

def get_mondai_answer(mondai_main, answer):

    # 正解を取得
    mondai_kotae_elem = mondai_main.find_element(By.ID, kotae_dict_sentakusi[answer])
    kotae_text = f"{answer},{mondai_kotae_elem.text}"

    return kotae_text

def get_mondai_failure(mondai_main, answer):
    matigai_ls = ["select_a", "select_i", "select_u", "select_e"]
    matigai_ls.remove(kotae_dict_sentakusi[answer])
    matigai_texts = []
    for matigai in matigai_ls:
        matigai_elem = mondai_main.find_element(By.ID, matigai)
        matigai_text = f"{kotae_dict_sentakusi_r[matigai]},{matigai_elem.text}"
        matigai_texts.append(matigai_text)

    return matigai_texts

def get_mondai_kaisetsu(mondai_main):
    # 解説を取得
    kaisetsu_div = mondai_main.find_element(By.ID, 'kaisetsu')
    kaisetu_all_text = kaisetsu_div.find_element(By.CLASS_NAME, 'R3tfxFm5').text


    return kaisetu_all_text

def tab_check():
    time.sleep(0.2)
    tab_cnt = driver.window_handles
    if len(tab_cnt) > 1:
        driver.switch_to.window(driver.window_handles[-1])
        driver.close()
        driver.switch_to.window(driver.window_handles[0])
    
    # 現在のURLが問題ページでない場合、問題ページに移動
    if driver.current_url != "https://www.fe-siken.com/fekakomon.php":
        driver.back()
        time.sleep(0.3)
    

while True:
    try:
        
        # この問題のデータすべて取得
        mondai_main = driver.find_element(By.CLASS_NAME, 'main')
        mondai_data = []

        # 問題文を取得
        mondai_bun = get_mondai_bun(mondai_main)
        # 問題文を追加
        mondai_data.append(mondai_bun)

        # 問題年度を取得
        mondai_nendo = get_mondai_nendo(mondai_main)
        # 問題年度を追加
        mondai_data.append(mondai_nendo)       


        # 問題カテゴリを取得
        category, series, stage = get_mondai_category(mondai_main)
        # 問題カテゴリを追加
        mondai_data.append([category, series, stage])

        time.sleep(0.2)
        # 答えと解説を表示
        answer_button = driver.find_element(By.ID, 'showAnswerBtn')
        time.sleep(0.3)
        answer_button.click()
        time.sleep(0.4)
        # 答え記号取得
        tab_check()
        answer = driver.find_element(By.ID, 'answerChar').text

        if answer == "":
            answer_button = driver.find_element(By.ID, 'showAnswerBtn')
            time.sleep(0.3)
            answer_button.click()
            time.sleep(0.4)
            # 答え記号取得
            tab_check()
            answer = driver.find_element(By.ID, 'answerChar').text

        # 正解を取得
        kotae_text = get_mondai_answer(mondai_main, answer)
        # 正解を追加
        mondai_data.append(kotae_text)

        # 間違い選択肢を取得,追加
        matigai_texts = get_mondai_failure(mondai_main, answer)
        mondai_data.append(matigai_texts)
        

        # 解説を取得
        kaisetsu = get_mondai_kaisetsu(mondai_main)
        # 解説を追加
        mondai_data.append(kaisetsu)

        # 問題データを追加
        mondai_datas.append(mondai_data)


        cnt += 1
        if cnt >= LOOP_TIMES:
            break

        # 次の問題へ
        next_button = driver.find_element(By.CLASS_NAME, 'submit')
        next_button.click()
        time.sleep(0.2)
    except Exception as e:
        print(e)
        print("エラーが発生したためスキップ")
        print("スキップした回数" + str(skip_count))
        skip_count += 1
        if skip_count >= 10:
            break
        try:
            next_button = driver.find_element(By.CLASS_NAME, 'submit')
            next_button.click()
            time.sleep(0.2)
        except:
            continue
        continue

print(mondai_datas)


# google spread関係

scope = [
    "https://spreadsheets.google.com/feeds",
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive.file",
    "https://www.googleapis.com/auth/drive"
]
creds = Credentials.from_service_account_file('cred.json', scopes=scope)

# Google Sheets APIに接続
client = gspread.authorize(creds)

# 対象のスプレッドシートを開く（シート名またはIDを指定）
spreadsheet = client.open_by_key(SPREAD_SHEET_ID)  # スプレッドシートIDを指定
sheet = spreadsheet.worksheet('問題')  # シート名を指定

# mondai_datasをGoogleスプレッドシートのフォーマットに変換して書き込む関数
def write_to_sheet(mondai_datas):
    for mondai in mondai_datas:
        mondai_bun = mondai[0]
        mondai_nendo = mondai[1]
        mondai_category = mondai[2][0]
        mondai_series = mondai[2][1]
        mondai_stage = mondai[2][2]
        mondai_answer = mondai[3]
        mondai_failure1 = mondai[4][0]
        mondai_failure2 = mondai[4][1]
        mondai_failure3 = mondai[4][2]
        mondai_comment = mondai[5]
        mondai_url = "null"  # もしリンクがあるなら、URLを追加

        # series_name　例外処理
        if mondai_series in series_reigai:
            mondai_series = series_reigai[mondai_series]
        
        # 番号割り振り
        if mondai_series in series_num:
            series_num_str = series_num[mondai_series]
        else:
            series_num_str = "0"
        
        if mondai_stage in stage_num.keys():
            stage_num_str = stage_num[mondai_stage]
        else:
            stage_num_str = "0"
        
        

        # スプレッドシートの列順にデータを並べる
        row = [
            "",       # id
            mondai_category,    # category
            series_num_str,      # series
            stage_num_str,       # stage
            mondai_series,       # series_name
            mondai_stage,       # stage_name
            mondai_bun,         # question
            mondai_answer,      # answer
            mondai_failure1,    # mistake1
            mondai_failure2,    # mistake2
            mondai_failure3,    # mistake3
            mondai_comment,     # comment
            mondai_url,          # url
            mondai_nendo        # year(link)
        ]
        
        # シートの最後に行を追加
        sheet.append_row(row, value_input_option='USER_ENTERED')

# 問題データをGoogleスプレッドシートに書き込む
write_to_sheet(mondai_datas)


# ユーザー操作を待機（無限ループでスクリプトを終了させない）
print("スキップした回数" + str(skip_count))
input("Enterキーを押すと終了")
driver.quit()