# スクレイピング
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from bs4 import BeautifulSoup, Tag
import time


# 定数
from controllers.sheet_controller import SheetController
from constants.series_data import SeriesData



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
TARGET_NENDO = "25_haru"
# 02免除より前は80問ある
LOOP_TIMES = 80
BEFORE_IMG = "<IMG>"
AFTER_IMG = "</IMG>"
BEFORE_SMALL_D_TEXT = "<SMALLD>"
AFTER_SMALL_D_TEXT = "</SMALLD>"
BEFORE_SMALL_U_TEXT = "<SMALLU>"
AFTER_SMALL_U_TEXT = "</SMALLU>"

mondai_datas = []
category_name = {"ストラテジ系": "strategyStage", "テクノロジ系": "technologyStage", "マネジメント系": "managementStage"}
kotae_dict = {"ア": "lia", "イ": "lii", "ウ": "liu", "エ": "lie"}
kotae_dict_sentakusi = {"ア": "select_a", "イ": "select_i", "ウ": "select_u", "エ": "select_e"}
kotae_dict_sentakusi_r = {"select_a": "ア", "select_i": "イ", "select_u": "ウ", "select_e": "エ"}

# ステージごとの数字データ
series_instance = SeriesData()
series_num = series_instance.series_num
stage_num = series_instance.stage_num

# スプレッドシートコントローラー
spread_instance = SheetController()


skip_count = 0
img_count = 0

# seleniumの設定

# オプション設定
chrome_options = Options()
chrome_options.add_experimental_option("detach", True)

service = Service(ChromeDriverManager().install())
# backgroundで動かす
chrome_options.add_argument('--headless')
driver = webdriver.Chrome(service=service, options=chrome_options)
wait = WebDriverWait(driver=driver, timeout=10)

def move_to_question():
    # 起動し、問題ページまで移動
    driver.get('https://www.fe-siken.com/fekakomon.php')
    check_all_wrap_div = driver.find_element(By.CLASS_NAME, 'check_all_wrap')
    buttons = check_all_wrap_div.find_elements(By.TAG_NAME, 'button')

    # ボタンのテキストが「OFF」のものをクリック
    for button in buttons:
        if button.text == 'OFF':
            button.click()
            break
    wait.until(EC.presence_of_all_elements_located)
    tab1_div = driver.find_element(By.ID, 'tab1')
    menjo_input = tab1_div.find_element(By.CSS_SELECTOR, f'input[value="{TARGET_NENDO}"]')
    menjo_input.click()
    wait.until(EC.presence_of_all_elements_located)
    submit_button = driver.find_element(By.XPATH, '/html/body/div[1]/div/main/div[2]/form/div[2]/button')
    submit_button.click()
    wait.until(EC.presence_of_all_elements_located)

move_to_question()

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
    # print("--------------------")
    # print(result_texts)
    # print("--------------------")
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

        # 問題年度を取得
        mondai_nendo = get_mondai_nendo(mondai_main)
        # 問題年度を追加
        mondai_data.append(mondai_nendo)       


        # 問題カテゴリを取得
        category, series, stage = get_mondai_category(mondai_main)
        # 問題カテゴリを追加
        mondai_data.append([category, series, stage])

        wait.until(EC.presence_of_all_elements_located)

        # 答えと解説を表示
        actions = ActionChains(driver)
        answer_button = driver.find_element(By.ID, 'showAnswerBtn')
        answer_button_style = answer_button.get_attribute('style')
        if "display: none;" not in answer_button_style:
            actions.move_to_element(answer_button).click().perform()
            wait.until(EC.presence_of_all_elements_located)


        # 答え記号取得
        tab_check()
        answer = driver.find_element(By.ID, 'answerChar').text

        # 画像を取得
        img_urls = get_img_url(mondai_main)
        img_url_str = "\n".join(img_urls)
        mondai_data.append(img_url_str)

        # 選択肢にfracがあればraise
        if mondai_main.find_element(By.CLASS_NAME, 'selectList').find_elements(By.CLASS_NAME, 'frac') != []:
            raise Exception("この問題は除外します。 (fracが含まれているため)")



        # 正解を取得
        kotae_text = get_mondai_answer(mondai_main, answer)
        # 正解を追加
        mondai_data.append(kotae_text)

        # 間違い選択肢を取得,追加
        if kotae_text[:4] == "null":
            print("選択肢がテキストではありません")
            matigai_texts = ["null", "null", "null"]
        else:
            matigai_texts = get_mondai_failure(mondai_main, answer)

        mondai_data.append(matigai_texts)
        

        # 解説を取得
        kaisetsu = get_mondai_kaisetsu(mondai_main)
        # 解説を追加
        mondai_data.append(kaisetsu)

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

        print('次の問題へ ' + str(cnt))
        print("==============================================")

    except KeyboardInterrupt:
        user_input = input("何も入れずで継続,exitで書き出し,quitで強制終了: ")
        if user_input == "exit":
            break
        elif user_input == "quit":
            print("スキップした回数" + str(skip_count))
            print("画像があった問題数" + str(img_count))
            driver.quit()
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


# 問題データを書き込む
spread_instance.write_to_sheet(mondai_datas)

print("問題データの書き込みが完了しました")
print('-' * 20)
print("スキップした回数" + str(skip_count))
print("画像があった問題数" + str(img_count))
input("Enterキーを押すと終了")
driver.quit()