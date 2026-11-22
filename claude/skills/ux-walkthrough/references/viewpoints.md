# 画面の種類ごとに見る点

通している画面の種類に当たる所だけを読む。全部を毎回確かめる表ではない。観察を出す時の手がかりにする。

## どの画面でも

- 次にすることが、画面の言葉から分かるか。画面の言葉は、利用者が使う言葉と同じか（作った側の用語になっていないか）。
- 操作の後、何が起きたかが分かるか。0.1 秒までは即時、1 秒までは流れが切れない、10 秒を超えるなら進み具合を見せる、が目安 [1]。
- 戻る・やり直すが効くか。戻った時に入力が残るか。
- 同じ意味のものが、画面ごとに違う名前・違う見た目になっていないか。

## 入力の画面

- 必須と任意の両方が分かるか。理由の分からない項目（電話番号など）に説明があるか。
- 同じ手続きの中で前に入れた情報を、もう一度入れさせていないか（WCAG 2.2 の 3.3.7） [2]。
- 貼り付けや自動入力を妨げていないか。覚える・書き写すことを必須にしていないか（3.3.8） [3]。
- 番号の類は、空白やハイフンが混ざっても受け付けるか [4]。

## 確認と確定の画面（支払い、送金、返金、引き出し）

- 総額（手数料を含む）が、支払いの情報を入れる前に見えているか [5]。
- 確定の前に、内容を見直して直せるか。直した後、確認の画面に戻れるか [6]。法的な約束やお金の取引では、取り消せる・誤りを直せる・確定の前に確認できる、のどれかが要る（3.3.4） [7]。
- 確定のボタンの文言が、押すと何が起きるかを言っているか（「次へ」ではなく、起きること） [6]。
- 取り消せない操作は、ひと呼吸おく作りになっているか。確認のダイアログは「よろしいですか」ではなく、何が起きるかを書いているか [8]。

## 待ちの画面

- 待っている間、何が起きているかが分かるか。閉じてよいのか、待つべきなのかが分かるか。
- 押した後、もう一度押せそうに見えないか。無効にしたボタンは、理由が分からず混乱のもとになる [9]。
- 時間切れがあるなら、切れる前に分かるか。延ばせるか（2.2.1） [10]。
- 状態の知らせ（処理中、完了、エラーの件数）は、フォーカスを奪わずに読み上げにも伝わるか（4.1.3） [11]。

## 完了の画面

- 照会の番号、次に何がいつ起きるか、問い合わせ先、記録を残す手段があるか [12]。
- 後から開き直した時（ブックマーク、再読み込み、戻る）に、もう一度確定されないか。何が出るか。

## 通し終えた後に、余力があれば（エラーからの戻り、2 度押し）

正常系を最後まで通して、結果を決めた後に行う。ここで見つけたことは控えるが、導線の「確認済み」の判断には入れない。深く探す時は exploratory-qa に渡す。導線ごとに 1 回、入力をわざと打ち間違える。確定のボタンを 2 度押して、2 重にならないかを見る（人が押す）。

- エラーの後、入れた内容が残っているか [13]。
- 文言が、何が起きたかと、どう直すかを言っているか。「無効です」で終わっていないか [14]。
- どの項目の誤りかが、文字で分かるか（3.3.1） [15]。
- 利用者には直せない問題（権限が無い、停止中）は、入力の誤りとして出さず、理由と次の手を説明しているか [13]。

## 出典

開いて読んだ資料。一部は取得ツールの要約を通して読んだので、文言の引用と調査の数値は、ここには写していない。

1. https://www.nngroup.com/articles/response-times-3-important-limits/
2. https://www.w3.org/WAI/WCAG22/Understanding/redundant-entry.html
3. https://www.w3.org/WAI/WCAG22/Understanding/accessible-authentication-minimum.html
4. https://design-system.service.gov.uk/patterns/payment-card-details/
5. https://baymard.com/blog/payment-ux
6. https://design-system.service.gov.uk/patterns/check-answers/
7. https://www.w3.org/WAI/WCAG22/Understanding/error-prevention-legal-financial-data.html
8. https://www.nngroup.com/articles/confirmation-dialog/
9. https://design-system.service.gov.uk/components/button/
10. https://www.w3.org/WAI/WCAG22/Understanding/timing-adjustable.html
11. https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html
12. https://design-system.service.gov.uk/patterns/confirmation-pages/
13. https://design-system.service.gov.uk/patterns/validation/
14. https://design-system.service.gov.uk/components/error-message/
15. https://www.w3.org/WAI/WCAG22/Understanding/error-identification.html
