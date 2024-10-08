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

# --- 2. 'tab1'のidを持つdiv内の、'05_menjo'のvalueを持つinputをクリック ---
# 'tab1'のidを持つdivを探す
tab1_div = driver.find_element(By.ID, 'tab1')

# '05_menjo'のvalueを持つinputを探す
menjo_input = tab1_div.find_element(By.CSS_SELECTOR, 'input[value="05_menjo"]')

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
    kotae_text = mondai_kotae_elem.text

    return kotae_text

def get_mondai_failure(mondai_main, answer):
    matigai_ls = ["select_a", "select_i", "select_u", "select_e"]
    matigai_ls.remove(kotae_dict_sentakusi[answer])
    matigai_texts = []
    for matigai in matigai_ls:
        matigai_elem = mondai_main.find_element(By.ID, matigai)
        matigai_texts.append(matigai_elem.text)

    return matigai_texts

def get_mondai_kaisetsu(mondai_main):
    # 解説を取得
    kaisetsu_div = mondai_main.find_element(By.ID, 'kaisetsu')
    kaisetu_all_text = kaisetsu_div.find_element(By.CLASS_NAME, 'R3tfxFm5').text


    return kaisetu_all_text

def tab_check():
    tab_cnt = driver.window_handles
    if len(tab_cnt) > 1:
        driver.switch_to.window(driver.window_handles[-1])
        driver.close()
        driver.switch_to.window(driver.window_handles[0])
    

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
        if cnt >= 10:
            break

        # 次の問題へ
        next_button = driver.find_element(By.CLASS_NAME, 'submit')
        next_button.click()
        time.sleep(0.5)
    except Exception as e:
        print(e)
        print("エラーが発生したためスキップ")
        skip_count += 1
        continue

print(mondai_datas)



# # ファイル名を指定してCSVに書き込む
# with open('mondai_datas.csv', 'w', newline='', encoding='utf-8') as csvfile:
#     writer = csv.writer(csvfile)
    
#     # ヘッダーを記入（任意）
#     writer.writerow(['question', 'link', 'category', 'series_name', 'stage_name', 'answer', 'failure1', 'failure2', 'failure3', 'comment'])
    
#     # データを一行ずつ書き込む
#     for mondai in mondai_datas:
#         mondai_bun = mondai[0]
#         mondai_nendo = mondai[1]
#         mondai_category = mondai[2][0]
#         mondai_series = mondai[2][1]
#         mondai_stage = mondai[2][2]
#         mondai_answer = mondai[3]
#         mondai_failure1 = mondai[4][0]
#         mondai_failure2 = mondai[4][1]
#         mondai_failure3 = mondai[4][2]
#         mondai_comment = mondai[5]
#         print('-' * 20)
#         print(mondai_bun)
#         print('-' * 20)
#         print(mondai_nendo)
#         print('-' * 20)
#         print(mondai_category)
#         print('-' * 20)
#         print(mondai_series)
#         print('-' * 20)
#         print(mondai_stage)
#         print('-' * 20)
#         print(mondai_answer)
#         print('-' * 20)
#         print(mondai_failure1)
#         print(mondai_failure2)
#         print(mondai_failure3)
#         print('-' * 20)
#         print(mondai_comment)
#         print('-' * 20)
#         writer.writerow([mondai_bun, mondai_nendo, mondai_category, mondai_series, mondai_stage, mondai_answer, mondai_failure1, mondai_failure2, mondai_failure3, mondai_comment])



# print("CSVファイルにデータを書き出しました")


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

        
        # スプレッドシートの列順にデータを並べる
        row = [
            "",       # id
            mondai_category,    # category
            '1001',      # series
            '10010001',       # stage
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