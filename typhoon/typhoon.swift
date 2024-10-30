import Foundation

class TyphoonDataFetcher {
    let urlString = "https://www.dgpa.gov.tw/typh/daily/nds.html"
    
    struct CityStatus {
        let city: String
        let status: String
    }
    
    struct FetchResult {
        let cityStatuses: [CityStatus]
        let usedEncoding: String
        let dataSize: Int
    }
    
    typealias FetchCompletion = (FetchResult) -> Void
    
    func fetchSourceCode(completion: @escaping FetchCompletion) {
        guard let url = URL(string: urlString) else {
            completion(FetchResult(
                cityStatuses: [],
                usedEncoding: "URL錯誤",
                dataSize: 0
            ))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.setValue("big5,utf-8", forHTTPHeaderField: "Accept-Charset")
        request.setValue("zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7", forHTTPHeaderField: "Accept-Language")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("網路錯誤：\(error.localizedDescription)")
                completion(FetchResult(
                    cityStatuses: [],
                    usedEncoding: "網路錯誤",
                    dataSize: 0
                ))
                return
            }
            
            guard let data = data else {
                completion(FetchResult(
                    cityStatuses: [],
                    usedEncoding: "無數據",
                    dataSize: 0
                ))
                return
            }
            
            // 嘗試多種編碼
            let encodings: [(String.Encoding, String)] = [
                (String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.big5.rawValue))), "Big5"),
                (.utf8, "UTF-8"),
                (String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.dosChineseTrad.rawValue))), "DOS Chinese Trad")
            ]
            
            var decodedString: String?
            var usedEncoding = ""
            
            for (encoding, name) in encodings {
                if let decoded = String(data: data, encoding: encoding) {
                    decodedString = decoded
                    usedEncoding = name
                    break
                }
            }
            
            var results: [CityStatus] = []
            
            if let htmlString = decodedString {
                // 找到 TBODY 內容
                if let tbodyStart = htmlString.range(of: "<TBODY class=\"Table_Body\">"),
                   let tbodyEnd = htmlString.range(of: "</TBODY>", range: tbodyStart.upperBound..<htmlString.endIndex) {
                    
                    let tbodyContent = String(htmlString[tbodyStart.upperBound..<tbodyEnd.lowerBound])
                    let rows = tbodyContent.components(separatedBy: "<TR>")
                    
                    for row in rows where !row.isEmpty {
                        // 提取縣市名稱
                        if let cityStart = row.range(of: "<FONT >"),
                           let cityEnd = row.range(of: "</FONT>", range: cityStart.upperBound..<row.endIndex) {
                            let cityName = String(row[cityStart.upperBound..<cityEnd.lowerBound])
                            
                            // 提取停班停課資訊（包括紅色字體）
                            var info = ""
                            if let infoStart = row.range(of: "<FONT color=#000000 >") ?? row.range(of: "<FONT color=#FF0000 >"),
                               let infoEnd = row.range(of: "</FONT>", range: infoStart.upperBound..<row.endIndex) {
                                info = String(row[infoStart.upperBound..<infoEnd.lowerBound])
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                // 檢查是否有第二行紅色文字
                                if let secondInfoStart = row.range(of: "<FONT color=#FF0000 >", range: infoEnd.upperBound..<row.endIndex),
                                   let secondInfoEnd = row.range(of: "</FONT>", range: secondInfoStart.upperBound..<row.endIndex) {
                                    let secondInfo = String(row[secondInfoStart.upperBound..<secondInfoEnd.lowerBound])
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                    info += "\n" + secondInfo
                                }
                            }
                            
                            results.append(CityStatus(city: cityName, status: info))
                        }
                    }
                }
                
                completion(FetchResult(
                    cityStatuses: results,
                    usedEncoding: usedEncoding,
                    dataSize: data.count
                ))
            } else {
                print("無法解析網頁內容")
                completion(FetchResult(
                    cityStatuses: [],
                    usedEncoding: "解析失敗",
                    dataSize: data.count
                ))
            }
        }
        
        task.resume()
    }
}
