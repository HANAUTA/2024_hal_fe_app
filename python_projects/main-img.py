from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup, Tag
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

import time


SPREAD_SHEET_ID = os.getenv("SPREAD_SHEET_IMG_ID")

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
TARGET_NENDO = "02_menjo"
# 02免除より前は80問ある
LOOP_TIMES = 80
BEFORE_IMG = "<IMG>"
AFTER_IMG = "</IMG>"
BEFORE_SMALL_D_TEXT = "<SMALLD>"
AFTER_SMALL_D_TEXT = "</SMALLD>"
BEFORE_SMALL_U_TEXT = "<SMALLU>"
AFTER_SMALL_U_TEXT = "</SMALLU>"


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
    mondaibun_text_list = []
    if cnt >= 1:
        mondai_bun = driver.find_element(By.XPATH, '/html/body/div[1]/div/main/div[2]/div[2]')

    else:
        mondai_bun = driver.find_element(By.XPATH, '/html/body/div[1]/div/main/div[2]/div[1]')


    # liがあればraise
    if mondai_bun.find_elements(By.TAG_NAME, 'li') != []:
        raise Exception("この問題は除外します。 (liが含まれているため)")
    # preがあればraise
    if mondai_bun.find_elements(By.CLASS_NAME, 'pre') != []:
        raise Exception("この問題は除外します。 (preが含まれているため)")
    
        # innerHTMLを取得し、BeautifulSoupでパース
    html_content = mondai_bun.get_attribute('innerHTML')
    soup = BeautifulSoup(html_content, 'html.parser')

    for elem in soup.contents:
        if elem.name == "div" and "img_margin" in (elem.get('class') or []):
            for img in elem.find_all('img'):
                mondaibun_text_list.append("\n")
                mondaibun_text_list.append(BEFORE_IMG + TARGET_NENDO + '/' + img.get('src').split("/img/")[1] + AFTER_IMG)
        elif elem.name == "br":
            mondaibun_text_list.append("\n")
        
        elif elem.name == "sup":
            mondaibun_text_list.append(BEFORE_SMALL_U_TEXT + elem.text + AFTER_SMALL_U_TEXT)
        else:
            mondaibun_text_list.append(elem.text)
    
    mondaibun_text = ''.join(mondaibun_text_list).strip()
    return mondaibun_text
    
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
    # 選択肢がテキストかどうか。
    if mondai_main.find_elements(By.ID, kotae_dict_sentakusi[answer]) == []:
        print("選択肢がありません")
        # 画像を取得
        img_src = mondai_main.find_element(By.CLASS_NAME, 'selectList').find_element(By.TAG_NAME, 'img').get_attribute('src').split("/img/")[1]
        return "null" + BEFORE_IMG + TARGET_NENDO + "/" + img_src + AFTER_IMG
    else:
        mondai_kotae_elem = mondai_main.find_element(By.ID, kotae_dict_sentakusi[answer])
        if mondai_kotae_elem.find_elements(By.TAG_NAME, 'img') != []:
            img_src = mondai_kotae_elem.find_element(By.TAG_NAME, 'img').get_attribute('src').split("/img/")[1]
            return f"{answer},{BEFORE_IMG + TARGET_NENDO + '/' + img_src + AFTER_IMG}"
        kotae_text = f"{answer},{mondai_kotae_elem.text}"

    return kotae_text

def get_mondai_failure(mondai_main, answer):
    matigai_ls = ["select_a", "select_i", "select_u", "select_e"]
    matigai_ls.remove(kotae_dict_sentakusi[answer])
    matigai_texts = []
    for matigai in matigai_ls:
        matigai_elem = mondai_main.find_element(By.ID, matigai)
        if matigai_elem.find_elements(By.TAG_NAME, 'img') != []:
            img_src = matigai_elem.find_element(By.TAG_NAME, 'img').get_attribute('src').split("/img/")[1]
            matigai_text = f"{kotae_dict_sentakusi_r[matigai]},{BEFORE_IMG + TARGET_NENDO + '/' + img_src + AFTER_IMG}"
            matigai_texts.append(matigai_text)
            continue
        matigai_text = f"{kotae_dict_sentakusi_r[matigai]},{matigai_elem.text}"
        matigai_texts.append(matigai_text)

    return matigai_texts


def mondai_kaisetsu_li(li):
    content_list = []
    lim_flag = False
    lir_flag = False
    lis_flag = False
    lisub_flag = False
    lisup_flag = False
    lib_flag = False
    lifrac_flag = False
    sentakusi_flag = False
    br_flag = False

    for li_elem in li.contents:
        # uがあればraise
        if li_elem.name == "u":
            raise Exception("この問題は除外します。 (uタグが含まれているため)")
        # class preがあればraise
        if li_elem.name == "div" and "pre" in (li_elem.get('class') or []):
            raise Exception("この問題は除外します。 (preタグが含まれているため)")
        if li_elem.name == "span" and "cite" in (li_elem.get('class') or []):
            sentakusi_flag = True
            # あ、い、う、えを表示
            if "lia" in li.get('class'):
                content_list.append("ア,")
            elif "lii" in li.get('class'):
                content_list.append("イ,")
            elif "liu" in li.get('class'):
                content_list.append("ウ,")
            elif "lie" in li.get('class'):
                content_list.append("エ,")
            
            # 画像ならば
            if li_elem.find_all('img') != []:
                for img in li_elem.find_all('img'):
                    content_list[-1] += BEFORE_IMG +TARGET_NENDO + '/' + img.get('src').split("/img/")[1] + AFTER_IMG
            else:
                content_list[-1] += li_elem.text
            continue
        else:
            if li_elem.name == "em" and "m" in (li_elem.get('class') or []):
                lim_flag = True
                if br_flag:
                    content_list.append(li_elem.text)
                else:
                    content_list[-1] += li_elem.text
            elif li_elem.name == "em" and "r" in (li_elem.get('class') or []):
                lir_flag = True
                if br_flag:
                    content_list.append(li_elem.text)
                else:
                    content_list[-1] += li_elem.text
            elif li_elem.name == "strong":
                lis_flag = True
                if br_flag:
                    content_list.append(li_elem.text)
                else:
                    content_list[-1] += li_elem.text
            elif isinstance(li_elem, Tag) and "img_margin" in (li_elem.get('class') or []):
                for img in li_elem.find_all('img'):
                    content_list.append(BEFORE_IMG +TARGET_NENDO + '/' + img.get('src').split("/img/")[1] + AFTER_IMG)
            elif li_elem.name == "sub":
                lisub_flag = True
                if br_flag:
                    content_list.append(BEFORE_SMALL_D_TEXT + li_elem.text + AFTER_SMALL_D_TEXT)
                else:
                    content_list[-1] += BEFORE_SMALL_D_TEXT + li_elem.text + AFTER_SMALL_D_TEXT
            elif li_elem.name == "sup":
                lisup_flag = True
                if br_flag:
                    content_list.append(BEFORE_SMALL_U_TEXT + li_elem.text + AFTER_SMALL_U_TEXT)
                else:
                    content_list[-1] += BEFORE_SMALL_U_TEXT + li_elem.text + AFTER_SMALL_U_TEXT
            elif li_elem.name == "b":
                lib_flag = True
                if br_flag:
                    content_list.append(li_elem.text)
                else:
                    content_list[-1] += li_elem.text
            elif li_elem.name == "span" and "frac" in (li_elem.get('class') or []):
                lifrac_flag = True
                for frac in li_elem.contents:
                    if frac.name == "sub":
                        content_list[-1] += BEFORE_SMALL_D_TEXT + frac.text + AFTER_SMALL_D_TEXT
                    elif frac.name == "sup":
                        content_list[-1] += BEFORE_SMALL_U_TEXT + frac.text + AFTER_SMALL_U_TEXT
                    elif frac.name == "span":
                        content_list[-1] += frac.text + "/"
                    else:
                        content_list[-1] += frac.text
            else:
                if lim_flag:
                    lim_flag = False
                    if br_flag:
                        content_list.append(li_elem.text)
                    else:
                        content_list[-1] += li_elem.text
                elif lir_flag:
                    lir_flag = False
                    if br_flag:
                        content_list.append(li_elem.text)
                    else:
                        content_list[-1] += li_elem.text
                elif lis_flag:
                    lis_flag = False
                    if br_flag:
                        content_list.append(li_elem.text)
                    else:
                        content_list[-1] += li_elem.text
                elif lisub_flag:
                    lisub_flag = False
                    if br_flag:
                        content_list.append(li_elem.text)
                    else:
                        content_list[-1] += li_elem.text
                elif lisup_flag:
                    lisup_flag = False
                    if br_flag:
                        content_list.append(li_elem.text)
                    else:
                        content_list[-1] += li_elem.text
                elif lib_flag:
                    lib_flag = False
                    if br_flag:
                        content_list.append(li_elem.text)
                    else:
                        content_list[-1] += li_elem.text
                elif lifrac_flag:
                    lifrac_flag = False
                    if br_flag:
                        content_list.append(li_elem.text)
                    else:
                        content_list[-1] += li_elem.text
                elif li_elem.name == "br":
                    br_flag = True
                    if sentakusi_flag:
                        sentakusi_flag = False
                    continue
                else:
                    lim_flag = False
                    lir_flag = False
                    lis_flag = False
                    lisub_flag = False
                    lisup_flag = False
                    lib_flag = False
                    lifrac_flag = False
                    content_list.append(li_elem.text)
            sentakusi_flag = False
            br_flag = False
    content_list.append("")
    return content_list

def get_mondai_kaisetsu(mondai_main):
    # 解説を含むdivを取得
    kaisetsu_div = mondai_main.find_element(By.ID, 'kaisetsu')
    kaisetu_element = kaisetsu_div.find_element(By.CLASS_NAME, 'R3tfxFm5')

    # 解説にfracがあればraise
    if kaisetu_element.find_elements(By.CLASS_NAME, 'frac') != []:   
        raise Exception("この問題は除外します。 (fracが含まれているため)")

    # innerHTMLを取得し、BeautifulSoupでパース
    html_content = kaisetu_element.get_attribute('innerHTML')
    soup = BeautifulSoup(html_content, 'html.parser')

    # 文章を取得
    result_texts = ""

    text_list = []
    tmp_text = ""
    r_flag = False
    sub_flag = False
    sup_flag = False
    b_flag = False
    emb_flag = False
    emg_flag = False
    s_flag = False
    m_flag = False
    frac_flag = False

    for elem in soup.contents:
        # uがあればraise
        if elem.name == "u":
            raise Exception("この問題は除外します。 (uタグが含まれているため)")
        # class preがあればraise
        if elem.name == "div" and "pre" in (elem.get('class') or []):
            raise Exception("この問題は除外します。 (preタグが含まれているため)")
        if elem.name == "ul":
            text_list.append("")
            text_list.append("")
            for li in elem.contents:
                if li.name == "ul":
                    for li in li.contents:
                        li_list = mondai_kaisetsu_li(li)
                        text_list.extend(li_list)
                else:   
                    li_list = mondai_kaisetsu_li(li)
                    text_list.extend(li_list)
            text_list.append("")
        elif elem.name == "ol":
            text_list.append("")
            for i, li in enumerate(elem.contents):
                tmp_text += str(i + 1) + ". " + li.text
                if li.name == "em":
                    continue
                text_list.append(str(tmp_text))
                tmp_text = ""
            text_list.append("")
        elif elem.name == "dl":
            text_list.append("")
            for dt in elem.contents:
                tmp_text += dt.text
                    
                text_list.append(str(tmp_text))
                tmp_text = ""
                if dt.name == "dd":
                    text_list.append("")
                    continue
                
            text_list.append("")
        elif isinstance(elem, Tag) and "img_margin" in (elem.get('class') or []):
            for img in elem.find_all('img'):
                text_list.append(BEFORE_IMG +TARGET_NENDO + '/' + img.get('alt') + AFTER_IMG)
        elif elem.name == "sub":
            sub_flag = True
            text_list[-1] += BEFORE_SMALL_D_TEXT + elem.text + AFTER_SMALL_D_TEXT
        elif elem.name == "sup":
            sub_flag = True
            text_list[-1] += BEFORE_SMALL_U_TEXT + elem.text + AFTER_SMALL_U_TEXT
        elif elem.name == "b":
            b_flag = True
            if len(text_list) == 0:
                text_list.append(elem.text)
            else:
                text_list[-1] += elem.text
        elif elem.name == "strong":
            s_flag = True
            if len(text_list) == 0:
                text_list.append(elem.text)
            else:
                text_list[-1] += elem.text
        elif elem.name == "em" and "m" in (elem.get('class') or []):
            m_flag = True
            text_list[-1] += elem.text
        elif elem.name == "em" and "r" in (elem.get('class') or []):
            r_flag = True
            text_list[-1] += elem.text
        elif elem.name == "em" and "b" in (elem.get('class') or []):
            emb_flag = True
            text_list[-1] += elem.text
        elif elem.name == "em" and "g" in (elem.get('class') or []):
            emg_flag = True
            text_list[-1] += elem.text
        elif elem.name == "span" and "frac" in (elem.get('class') or []):
            frac_flag = True
            for frac in elem.contents:
                if frac.name == "sub":
                    text_list[-1] += BEFORE_SMALL_D_TEXT + frac.text + AFTER_SMALL_D_TEXT
                elif frac.name == "sup":
                    text_list[-1] += BEFORE_SMALL_U_TEXT + frac.text + AFTER_SMALL_U_TEXT
                elif frac.name == "span":
                    text_list[-1] += frac.text + "/"
                else:
                    text_list[-1] += frac.text
        else:
            if r_flag:
                text_list[-1] += elem.text
                r_flag = False
            elif sub_flag:
                text_list[-1] += elem.text
                sub_flag = False
            elif sup_flag:
                text_list[-1] += elem.text
                sup_flag = False
            elif b_flag:
                text_list[-1] += elem.text
                b_flag = False
            elif emb_flag:
                text_list[-1] += elem.text
                emb_flag = False
            elif emg_flag:
                text_list[-1] += elem.text
                emg_flag = False
            elif s_flag:
                text_list[-1] += elem.text
                s_flag = False
            elif m_flag:
                text_list[-1] += elem.text
                m_flag = False
            elif frac_flag:
                text_list[-1] += elem.text
                frac_flag = False
            elif elem.name == "br":
                text_list.append("")
            else:
                r_flag = False
                sub_flag = False
                sup_flag = False
                b_flag = False
                emb_flag = False
                emg_flag = False
                s_flag = False
                m_flag = False
                frac_flag = False
                text_list.append(elem.text)

    result_texts = '\n'.join(text_list).strip()
    print("--------------------")
    print(result_texts)
    print("--------------------")
    return result_texts

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
        tab_check()

        # この問題のデータすべて取得
        mondai_main = driver.find_element(By.CLASS_NAME, 'main')
        mondai_data = []

        # 問題文fracがあればraise
        if mondai_main.find_elements(By.CLASS_NAME, 'frac') != []:
            raise Exception("この問題は除外します。 (fracが含まれているため)")
        
        # 問題文にタグがspanでクラスがolがあればraise
        if mondai_main.find_elements(By.TAG_NAME, 'span') != []:
            for span in mondai_main.find_elements(By.TAG_NAME, 'span'):
                if "ol" in span.get_attribute('class'):
                    raise Exception("この問題は除外します。 (span olが含まれているため)")
        
        # 問題文を取得
        mondai_bun = get_mondai_bun(mondai_main)
        # 問題文を追加
        mondai_data.append(mondai_bun)
        print('問題文取得済み')
        print("--------------------")
        print(mondai_bun)
        print("--------------------")

        # 問題年度を取得
        mondai_nendo = get_mondai_nendo(mondai_main)
        # 問題年度を追加
        mondai_data.append(mondai_nendo)       
        # print('問題年度取得済み')


        # 問題カテゴリを取得
        category, series, stage = get_mondai_category(mondai_main)
        # 問題カテゴリを追加
        mondai_data.append([category, series, stage])
        # print('問題カテゴリ取得済み')

        wait.until(EC.presence_of_all_elements_located)

        # 答えと解説を表示
        actions = ActionChains(driver)
        answer_button = driver.find_element(By.ID, 'showAnswerBtn')
        # print('答え表示ボタン取得')
        answer_button_style = answer_button.get_attribute('style')
        if "display: none;" not in answer_button_style:
            # print('答え表示ボタンクリック1')
            actions.move_to_element(answer_button).click().perform()
            # print('答え表示ボタンクリック2')
            wait.until(EC.presence_of_all_elements_located)
            # print('noneだった')

        # 答え記号取得
        tab_check()
        answer = driver.find_element(By.ID, 'answerChar').text
        # print('答え取得済み')

        # 画像を取得
        img_urls = get_img_url(mondai_main)
        img_url_str = "\n".join(img_urls)
        mondai_data.append(img_url_str)
        # print('画像取得済み')

        # 選択肢にfracがあればraise
        if mondai_main.find_element(By.CLASS_NAME, 'selectList').find_elements(By.CLASS_NAME, 'frac') != []:
            raise Exception("この問題は除外します。 (fracが含まれているため)")



        # 正解を取得
        kotae_text = get_mondai_answer(mondai_main, answer)
        # 正解を追加
        mondai_data.append(kotae_text)
        # print('正解取得済み')
        print("--------------------")
        print(kotae_text)
        print("--------------------")

        # 間違い選択肢を取得,追加
        if kotae_text[:4] == "null":
            print("選択肢がテキストではありません")
            matigai_texts = ["null", "null", "null"]
        else:
            matigai_texts = get_mondai_failure(mondai_main, answer)

        mondai_data.append(matigai_texts)
        # print('間違い選択肢取得済み')
        

        # 解説を取得
        kaisetsu = get_mondai_kaisetsu(mondai_main)
        # 解説を追加
        mondai_data.append(kaisetsu)
        # print('解説取得済み')

        # ID kaisetsu にスクロール
        driver.execute_script("document.getElementById('kaisetsu').scrollIntoView();")
        # 手動
        # y_n = input("この問題を採用しますか？(文字を入れたらno, exitで書き出し): ")
        # 自動
        y_n = ""
        if len(y_n) == 0:
            mondai_datas.append(mondai_data)
            print('問題データ取得完了')
        elif y_n == "exit":
            break
        else:
            print('問題データ破棄')


        cnt += 1
        if cnt >= LOOP_TIMES:
            break
        
        # 次の問題へ
        tab_check()
        next_button = driver.find_element(By.CLASS_NAME, 'submit')
        next_button.click()

        print('次の問題へ')
        print("==============================================")

    except KeyboardInterrupt:
        quit()
    
    except Exception as e:
        print(e)
        skip_count += 1
        print("エラーが発生したためスキップ")
        print("スキップした回数" + str(skip_count))
        # 手動
        # user_input = input("何も入れずで継続,exitで書き出し,quitで強制終了: ")
        # 自動
        user_input = ""
        if user_input == "exit":
            break
        elif user_input == "quit":
            print("スキップした回数" + str(skip_count))
            print("画像があった問題数" + str(img_count))
            driver.quit()
            quit()
        if skip_count >= 100:
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



def write_to_sheet(mondai_datas, batch_size=20):
    cnt = 1
    data_len = len(mondai_datas)

    # データを20行ずつに分割して書き込む
    for i in range(0, data_len, batch_size):
        batch = mondai_datas[i:i + batch_size]  # 20行ずつ取得
        rows = []

        for mondai in batch:
            print(f'{cnt}/{data_len}')
            cnt += 1
            
            # 各要素を取得
            mondai_bun = mondai[0]
            mondai_nendo = mondai[1]
            mondai_category = mondai[2][0]
            mondai_series = mondai[2][1]
            mondai_stage = mondai[2][2]
            mondai_answer = mondai[4]
            mondai_failure1 = mondai[5][0]
            mondai_failure2 = mondai[5][1]
            mondai_failure3 = mondai[5][2]
            mondai_comment = mondai[6]
            mondai_url = mondai[3] or "null"  # URLが空なら "null"

            # series_nameの例外処理
            if mondai_series in series_reigai:
                mondai_series = series_reigai[mondai_series]

            # 番号の割り振り
            series_num_str = series_num.get(mondai_series, "0")
            stage_num_str = stage_num.get(mondai_stage, "0")

            # スプレッドシートの列順にデータを並べる
            row = [
                "",       # id
                mondai_category,    # category
                series_num_str,     # series
                stage_num_str,      # stage
                mondai_series,      # series_name
                mondai_stage,       # stage_name
                mondai_bun,         # question
                mondai_answer,      # answer
                mondai_failure1,    # mistake1
                mondai_failure2,    # mistake2
                mondai_failure3,    # mistake3
                mondai_comment,     # comment
                mondai_url,         # url
                mondai_nendo        # year(link)
            ]

            rows.append(row)  # 行を追加

        # 20行をまとめて書き込む
        print(f"{cnt-1}行目まで書き込み中...")
        sheet.append_rows(rows, value_input_option='USER_ENTERED')

        # API制限を避けるための待機時間
        time.sleep(2)  # 2秒待機

# 問題データを書き込む
print("問題データを書き込み中...")
write_to_sheet(mondai_datas)


# ユーザー操作を待機（無限ループでスクリプトを終了させない）
print('-' * 20)
print("スキップした回数" + str(skip_count))
print("画像があった問題数" + str(img_count))
input("Enterキーを押すと終了")
driver.quit()