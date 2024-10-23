from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
import time
import csv
import gspread
from google.oauth2.service_account import Credentials

from dotenv import load_dotenv
import os

# wait系
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from webdriver_manager.chrome import ChromeDriverManager


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
23_toku
22_aki
22_haru
21_aki
21_haru
20_aki
20_haru
"""
TARGET_NENDO = "05_menjo"
# 02免除より前は80問ある
LOOP_TIMES = 80

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
    "離散数学": "10010001",
    "応用数学": "10010002",
    "情報理論": "10010003",
    "情報に関する理論": "10010003",
    "通信理論": "10010004",
    "通信に関する理論": "10010004",
    "計測制御理論": "10010005",
    "計測・制御に関する理論": "10010005",
    
    "データ構造": "10020001",
    "アルゴリズム": "10020002",
    "プログラミング": "10020003",
    "プログラム言語": "10020004",
    "マークアップ言語など": "10020005",
    "その他の言語": "10020005",
    
    "プロセッサ": "10030001",
    "メモリ": "10030002",
    "バス": "10030003",
    "入出力デバイス": "10030004",
    "入出力装置": "10030005",
    
    "システムの構成": "10040001",
    "システム評価指標": "10040002",
    "システムの評価指標": "10040002",
    
    "オペレーティングシステム": "10050001",
    "ミドルウェア": "10050002",
    "ファイルシステム": "10050003",
    "開発ツール": "10050004",
    "オープンソースソフトウェア": "10050005",
    
    "ハードウェア全般": "10060001",
    "ハードウェア": "10060001",
    
    "ヒューマンインターフェイス技術": "10070001",
    "ユーザーインタフェース技術": "10070001",
    "UX/UIデザイン": "10070001",
    "インターフェイス設計": "10070002",
    
    "マルチメディア技術": "10080001",
    "マルチメディア応用": "10080002",
    
    "データベース方式": "10090001",
    "データベース設計": "10090002",
    "データ操作": "10090003",
    "トランザクション処理": "10090004",
    "データベース応用": "10090005",
    
    "ネットワーク方式": "10100001",
    "データ通信と制御": "10100002",
    "通信プロトコル": "10100003",
    "ネットワーク管理": "10100004",
    "ネットワーク応用": "10100005",
    
    "情報セキュリティ": "10110001",
    "情報セキュリティ管理": "10110002",
    "セキュリティ技術評価": "10110003",
    "情報セキュリティ対策": "10110004",
    "セキュリティ実装技術": "10110005",
    
    "システム要件定義／ソフトウェア要件定義": "10120001",
    "システム要件定義": "10120001",
    "ソフトウェア要件定義": "10120001",
    "設計": "10120002",
    "ソフトウェア方式設計・詳細設計": "10120002",
    "実装／構築": "10120003",
    "ソフトウェア構築": "10120003",
    "結合／テスト": "10120004",
    "ソフトウェア結合・適格性テスト": "10120004",
    "システム結合・適格性テスト": "10120004",
    "導入／受入支援": "10120005",
    "受入れ支援": "10120005",
    "保守／廃棄": "10120006",
    "保守・廃棄": "10120006",
    
    "開発プロセス・手法": "10130001",
    "知的財産適用管理": "10130002",
    "開発環境管理": "10130003",
    "構成管理／変更管理": "10130004",
    "構成管理・変更管理": "10130004",
    
    "プロジェクトマネジメント": "20010001",
    "プロジェクトの統合": "20010002",
    "プロジェクトのステークホルダ": "20010003",
    "プロジェクトのスコープ": "20010004",
    "プロジェクトの資源": "20010005",
    "プロジェクトの時間": "20010006",
    "プロジェクトのコスト": "20010007",
    "プロジェクトのリスク": "20010008",
    "プロジェクトの品質": "20010009",
    "プロジェクトの調達": "20010010",
    "プロジェクトのコミュニケーション": "20010011",
    
    "サービスマネジメント": "20020001",
    "サービスマネジメントシステムの計画及び運用": "20020002",
    "サービスの設計・移行": "20020002",
    "サービスマネジメントプロセス": "20020002",
    "パフォーマンス評価及び改善": "20020003",
    "サービスの運用": "20020004",
    "ファシリティマネジメント": "20020005",
    
    "システム監査": "20030001",
    "内部統制": "20030002",
    
    "情報システム戦略": "30010001",
    "業務プロセス": "30010002",
    "ソリューションビジネス": "30010003",
    "システム活用促進評価": "30010004",
    "システム活用促進・評価": "30010004",
    
    "システム化計画": "30020001",
    "要件定義": "30020002",
    "調達計画／実施": "30020003",
    "調達計画・実施": "30020003",
    
    "経営戦略手法": "30030001",
    "マーケティング": "30030002",
    "ビジネス戦略と目標・評価": "30030003",
    "経営管理システム": "30030004",
    
    "技術開発戦略の立案": "30040001",
    "技術開発計画": "30040002",
    
    "ビジネスシステム": "30050001",
    "エンジニアリングシステム": "30050002",
    "e-ビジネス": "30050003",
    "民生機器": "30050004",
    "産業機器": "30050005",
    
    "経営組織論": "30060001",
    "経営・組織論": "30060001",
    "OR／IE": "30060002",
    "業務分析・データ利活用": "30060002",
    "会計財務": "30060003",
    "会計・財務": "30060003",
    
    "知的財産権": "30070001",
    "セキュリティ関連法規": "30070002",
    "労働関連/取引関連法規": "30070003",
    "労働関連・取引関連法規": "30070003",
    "その他の法律／ガイドライン／技術者倫理": "30070004",
    "その他の法律・ガイドライン": "30070004",
    "標準化関連": "30070005"
}



# for debug
skip_count = 0

# img_count
img_count = 0

# オプション設定
chrome_options = Options()
chrome_options.add_experimental_option("detach", True)

# Chromeドライバーの自動設定
service = Service(ChromeDriverManager().install())
# backgroundで動かす
# chrome_options.add_argument('--headless')
driver = webdriver.Chrome(service=service, options=chrome_options)

# 最大の読み込み時間を設定 今回は最大30秒待機できるようにする
wait = WebDriverWait(driver=driver, timeout=10)

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
wait.until(EC.presence_of_all_elements_located)

# --- 2. 'tab1'のidを持つdiv内の、'target_nendo'のvalueを持つinputをクリック ---
# 'tab1'のidを持つdivを探す
tab1_div = driver.find_element(By.ID, 'tab1')

# 'target_nendo'のvalueを持つinputを探す
menjo_input = tab1_div.find_element(By.CSS_SELECTOR, f'input[value="{TARGET_NENDO}"]')

# inputをクリック
menjo_input.click()

# 少し待機（次の操作に備えて）
wait.until(EC.presence_of_all_elements_located)


# --- 3. XPathを使って指定されたボタンをクリック ---
# 指定されたXPathのボタンをクリック
submit_button = driver.find_element(By.XPATH, '/html/body/div[1]/div/main/div[2]/form/div[2]/button')

# ボタンをクリック
submit_button.click()

# 少し待機して処理が完了するまで待つ
wait.until(EC.presence_of_all_elements_located)


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
    # 解説を含むdivを取得
    kaisetsu_div = mondai_main.find_element(By.ID, 'kaisetsu')
    kaisetu_element = kaisetsu_div.find_element(By.CLASS_NAME, 'R3tfxFm5')

    # innerHTMLを取得し、BeautifulSoupでパース
    html_content = kaisetu_element.get_attribute('innerHTML')
    soup = BeautifulSoup(html_content, 'html.parser')

    # 文章を取得
    result_texts = []

    # <ul>以外のテキストを取得し、<br>を改行に変更
    for elem in soup.contents:
        if elem.name != 'ul':
            text_with_breaks = elem.get_text(separator='\n', strip=True)
            result_texts.append(text_with_breaks)

    # <ul>の内容を取得
    for ul in soup.find_all('ul'):
        result_texts.append("")  # 空白行1
        result_texts.append("")  # 空白行2
        
        for li in ul.find_all('li'):
            # li要素内のテキストを取得し、<br>を改行に変換
            text_with_breaks = li.get_text(separator='', strip=True)
            for br in li.find_all('br'):
                text_with_breaks = text_with_breaks.replace(br.string, '\n')
            result_texts.append(text_with_breaks)
            result_texts.append("")  # liごとの間に空白行1つ

        result_texts.append("")  # ulの後の空白行1つ

    # 最終的な結果を連結
    final_result = "\n".join(result_texts).strip()

    return final_result

def tab_check():
    wait.until(EC.presence_of_all_elements_located)
    tab_cnt = driver.window_handles
    if len(tab_cnt) > 1:
        driver.switch_to.window(driver.window_handles[-1])
        driver.close()
        driver.switch_to.window(driver.window_handles[0])
    
    # 現在のURLが問題ページでない場合、問題ページに移動
    if driver.current_url != "https://www.fe-siken.com/fekakomon.php":
        driver.back()
        wait.until(EC.presence_of_all_elements_located)


def get_img_url(mondai_main):
    imgs = mondai_main.find_elements(By.TAG_NAME, 'img')
    # すべての画像のsrcを取得
    # 画像があればそのURLを取得しlistで返す
    img_urls = []
    if len(imgs) > 0:
        global img_count
        img_count += 1
        for img in imgs:
            img_urls.append(img.get_attribute('src'))
    return img_urls


while True:
    try:
        wait.until(EC.presence_of_all_elements_located)

        # この問題のデータすべて取得
        mondai_main = driver.find_element(By.CLASS_NAME, 'main')
        mondai_data = []

        # 問題文を取得
        mondai_bun = get_mondai_bun(mondai_main)
        # 問題文を追加
        mondai_data.append(mondai_bun)
        print('問題文取得済み')

        # 問題年度を取得
        mondai_nendo = get_mondai_nendo(mondai_main)
        # 問題年度を追加
        mondai_data.append(mondai_nendo)       
        print('問題年度取得済み')


        # 問題カテゴリを取得
        category, series, stage = get_mondai_category(mondai_main)
        # 問題カテゴリを追加
        mondai_data.append([category, series, stage])
        print('問題カテゴリ取得済み')

        wait.until(EC.presence_of_all_elements_located)

        # 答えと解説を表示
        actions = ActionChains(driver)
        answer_button = driver.find_element(By.ID, 'showAnswerBtn')
        print('答え表示ボタン取得')
        answer_button_style = answer_button.get_attribute('style')
        if "display: none;" not in answer_button_style:
            print('答え表示ボタンクリック1')
            actions.move_to_element(answer_button).click().perform()
            print('答え表示ボタンクリック2')
            wait.until(EC.presence_of_all_elements_located)
            print('noneだった')

        # 答え記号取得
        tab_check()
        answer = driver.find_element(By.ID, 'answerChar').text
        print('答え取得済み')

        # 画像を取得
        img_urls = get_img_url(mondai_main)
        mondai_data.append(img_urls)
        print('画像取得済み')
        print(img_urls)


        # 正解を取得
        kotae_text = get_mondai_answer(mondai_main, answer)
        # 正解を追加
        mondai_data.append(kotae_text)
        print('正解取得済み')

        # 間違い選択肢を取得,追加
        matigai_texts = get_mondai_failure(mondai_main, answer)
        mondai_data.append(matigai_texts)
        print('間違い選択肢取得済み')
        

        # 解説を取得
        kaisetsu = get_mondai_kaisetsu(mondai_main)
        # 解説を追加
        mondai_data.append(kaisetsu)
        print(kaisetsu)
        print('解説取得済み')

        
        mondai_datas.append(mondai_data)
        print('問題データ取得完了')


        cnt += 1
        if cnt >= LOOP_TIMES:
            break
        
        input("一時停止")
        # 次の問題へ
        tab_check()
        next_button = driver.find_element(By.CLASS_NAME, 'submit')
        next_button.click()

        print('次の問題へ')

    except KeyboardInterrupt:
        quit()
    
    except Exception as e:
        print(e)
        skip_count += 1
        print("エラーが発生したためスキップ")
        print("スキップした回数" + str(skip_count))
        user_input = input("何も入れずで継続,exitで書き出し,quitで強制終了: ")
        if user_input == "exit":
            break
        elif user_input == "quit":
            print("スキップした回数" + str(skip_count))
            print("画像があった問題数" + str(img_count))
            driver.quit()
            quit()
        if skip_count >= 20:
            break
        try:
            next_button = driver.find_element(By.CLASS_NAME, 'submit')
            next_button.click()
            wait.until(EC.presence_of_all_elements_located)

        except:
            continue
        continue



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
        mondai_answer = mondai[4]
        mondai_failure1 = mondai[5][0]
        mondai_failure2 = mondai[6][1]
        mondai_failure3 = mondai[7][2]
        mondai_comment = mondai[6]
        mondai_url = mondai[3]  

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
print("問題データを書き込み中...")
write_to_sheet(mondai_datas)


# ユーザー操作を待機（無限ループでスクリプトを終了させない）
print('-' * 20)
print("スキップした回数" + str(skip_count))
print("画像があった問題数" + str(img_count))
input("Enterキーを押すと終了")
driver.quit()