import os
from constants.series_data import SeriesData
from constants.spread_data import SpreadData
# spread sheetへの書き込み
import gspread
from google.oauth2.service_account import Credentials
import time

class SheetController:
    def __init__(self):
        self.series_instance = SeriesData()
        self.series_reigai = self.series_instance.series_reigai
        self.stage_num = self.series_instance.stage_num
        self.series_num = self.series_instance.series_num
        self.SPREAD_SHEET_ID = os.getenv("SPREAD_SHEET_ID")

        # スプレッドシートのデータ
        self.spread_instance = SpreadData()
        self.scope = self.spread_instance.scope
        

        # google spread関係
        creds = Credentials.from_service_account_file('cred.json', scopes=self.scope)
        # Google Sheets APIに接続
        self.client = gspread.authorize(creds)



    def get_sheet(self):
        # 対象のスプレッドシートを開く（シート名またはIDを指定）
        spreadsheet = self.client.open_by_key(self.SPREAD_SHEET_ID)  # スプレッドシートIDを指定
        self.sheet = spreadsheet.worksheet('問題')  # シート名を指定

    def write_to_sheet(self, mondai_datas, batch_size=20):
        self.get_sheet()
        print("問題データを書き込み中...")
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
                if mondai_series in self.series_reigai:
                    mondai_series = self.series_reigai[mondai_series]

                # 番号の割り振り
                series_num_str = self.series_num.get(mondai_series, "0")
                stage_num_str = self.stage_num.get(mondai_stage, "0")

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
            self.sheet.append_rows(rows, value_input_option='USER_ENTERED')

            # API制限を避けるための待機秒数
            time.sleep(2)