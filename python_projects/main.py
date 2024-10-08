from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
import time
import csv


mondai_datas = []

# オプション設定
chrome_options = Options()
chrome_options.add_experimental_option("detach", True)

# Chromeドライバーの自動設定
service = Service(ChromeDriverManager().install())
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
time.sleep(1)

# --- 2. 'tab1'のidを持つdiv内の、'05_menjo'のvalueを持つinputをクリック ---
# 'tab1'のidを持つdivを探す
tab1_div = driver.find_element(By.ID, 'tab1')

# '05_menjo'のvalueを持つinputを探す
menjo_input = tab1_div.find_element(By.CSS_SELECTOR, 'input[value="05_menjo"]')

# inputをクリック
menjo_input.click()

# 少し待機（次の操作に備えて）
time.sleep(1)

# --- 3. XPathを使って指定されたボタンをクリック ---
# 指定されたXPathのボタンをクリック
submit_button = driver.find_element(By.XPATH, '/html/body/div[1]/div/main/div[2]/form/div[2]/button')

# ボタンをクリック
submit_button.click()

# 少し待機して処理が完了するまで待つ
time.sleep(1)

cnt = 0
while True:
    mondai_main = driver.find_element(By.CLASS_NAME, 'main')
    mondai_data = []
    if cnt >= 1:
        mondai_bun = driver.find_element(By.XPATH, '/html/body/div[1]/div/main/div[2]/div[2]')
    else:
        mondai_bun = driver.find_element(By.XPATH, '/html/body/div[1]/div/main/div[2]/div[1]')
    mondai_data.append(mondai_bun.text)
    mondai_kotae_list = mondai_main.find_element(By.CLASS_NAME, 'selectList')
    # 'li'要素を全て取得
    mondai_kotae = mondai_kotae_list.find_elements(By.TAG_NAME, 'li')

    # 各li要素の中にあるspanタグのテキストを取得
    kotaes = []
    for kotae in mondai_kotae:
        kotae_text = kotae.find_element(By.TAG_NAME, 'span').text
        kotaes.append(kotae_text)
    

    mondai_data.append(kotaes)

    # 問題年度を取得
    mondai_nendo = mondai_main.find_element(By.CLASS_NAME, 'anslink').text

    mondai_data.append(mondai_nendo)

    mondai_category = mondai_main.find_element(By.TAG_NAME, 'p').text
    mondai_data.append(mondai_category)



    mondai_datas.append(mondai_data)


    cnt += 1

    if cnt >= 10:
        break

    # 次の問題へ
    next_button = driver.find_element(By.CLASS_NAME, 'submit')
    next_button.click()
    time.sleep(0.5)


print(mondai_datas)
# ユーザー操作を待機（無限ループでスクリプトを終了させない）
input("Enterキーを押すとcsvに保存します")
driver.quit()

# ファイル名を指定してCSVに書き込む
with open('mondai_datas.csv', 'w', newline='', encoding='utf-8') as csvfile:
    writer = csv.writer(csvfile)
    
    # ヘッダーを記入（任意）
    writer.writerow(['問題文', '選択肢ア', '選択肢イ', '選択肢ウ', '選択肢エ', '年度', 'カテゴリ'])
    
    # データを一行ずつ書き込む
    for mondai in mondai_datas:
        # 問題文、選択肢（リストを結合して1つの文字列にする）、年度、カテゴリを一行として書き込む
        mondai_bun = mondai[0].replace('\n', ' ')
        mondai_kotae = mondai[1]
        mondai_kotae_a = mondai_kotae[0].replace('\n', ' ')
        mondai_kotae_i = mondai_kotae[1].replace('\n', ' ')
        mondai_kotae_u = mondai_kotae[2].replace('\n', ' ')
        mondai_kotae_e = mondai_kotae[3].replace('\n', ' ')
        mondai_nendo = mondai[2].replace('\n', ' ').split('／')[0]
        mondai_category = mondai[3]
        print('-' * 20)
        print(mondai_bun)
        print('-' * 20)
        print(mondai_kotae_a)
        print(mondai_kotae_i)
        print(mondai_kotae_u)
        print(mondai_kotae_e)
        print('-' * 20)
        print(mondai_nendo)
        print('-' * 20)
        print(mondai_category)
        print('-' * 20)

        writer.writerow([mondai_bun, mondai_kotae_a, mondai_kotae_i, mondai_kotae_u, mondai_kotae_e, mondai_nendo, mondai_category])

print("CSVファイルにデータを書き出しました")