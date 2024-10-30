//
//  ViewController.swift
//  typhoon
//
//  Created by abcxyz on 2024/10/30.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    // 添加 label 属性
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "颱風假不假"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // 添加县市数据
    private let cities = ["台北市", "新北市", "桃園市", "台中市", "台南市", "高雄市", 
                         "基隆市", "新竹市", "嘉義市", "新竹縣", "苗栗縣", "彰化縣", 
                         "南投縣", "雲林縣", "嘉義縣", "屏東縣", "宜蘭縣", "花蓮縣", 
                         "台東縣", "澎湖縣", "金門縣", "連江縣"]

    // 添加 UIPickerView
    private let cityPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    // 添加结果 label 属性
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.text = "載入中..."
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // 添加图片视图
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "karaoke_scene")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    // 添加一个显示编码信息的标签
    private let encodingLabel: UILabel = {
        let label = UILabel()
        label.text = "編碼: 等待資料..."
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let typhoonFetcher = TyphoonDataFetcher()
    private var cityStatuses: [TyphoonDataFetcher.CityStatus] = []
    private var audioPlayer: AVAudioPlayer?

    // 添加播放按钮
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("播放音樂", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置音频会话
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("设置音频会话失败: \(error)")
        }
        
        setupUI()
        fetchTyphoonData()
        setupAudioPlayer()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 添加 label 到视图并设置约束
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        // 设置 UIPickerView
        view.addSubview(cityPicker)
        cityPicker.delegate = self
        cityPicker.dataSource = self
        
        // 添加 UIPickerView 约束
        NSLayoutConstraint.activate([
            cityPicker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            cityPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cityPicker.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])

        // 添加结果 label 和图片视图到视图并设置约束
        view.addSubview(resultLabel)
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            resultLabel.topAnchor.constraint(equalTo: cityPicker.bottomAnchor, constant: 20),
            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            imageView.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])

        // 添加编码标签的约束
        view.addSubview(encodingLabel)
        NSLayoutConstraint.activate([
            encodingLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 10),
            encodingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            encodingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        // 添加播放按钮
        view.addSubview(playButton)
        NSLayoutConstraint.activate([
            playButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 120),
            playButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        // 添加按钮点击事件
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
    }
    
    private func fetchTyphoonData() {
        resultLabel.text = "正在獲取資料..."
        encodingLabel.text = "編碼: 載入中..."
        
        typhoonFetcher.fetchSourceCode { [weak self] result in
            DispatchQueue.main.async {
                self?.cityStatuses = result.cityStatuses
                self?.cityPicker.reloadAllComponents()
                
                // 更新编码信息
                self?.encodingLabel.text = "編碼: \(result.usedEncoding) (數據大小: \(result.dataSize) bytes)"
                
                if !result.cityStatuses.isEmpty {
                    self?.updateResultLabel(for: 0)
                } else {
                    self?.resultLabel.text = "暫無資料"
                }
            }
        }
    }
    
    private func updateResultLabel(for row: Int) {
        guard row < cityStatuses.count else { return }
        let status = cityStatuses[row]
        resultLabel.text = status.status.isEmpty ? "暫無資訊" : status.status
    }

    private func setupAudioPlayer() {
        // 获取当前 Bundle 的路径
        let bundlePath = Bundle.main.bundlePath
        // 构建音频文件的完整路径（使用新的音乐文件名）
        let audioPath = (bundlePath as NSString).deletingLastPathComponent + "/放假.mp3"
        let url = URL(fileURLWithPath: audioPath)
        
        // 检查文件是否存在
        if FileManager.default.fileExists(atPath: audioPath) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
                print("音频播放器初始化成功，文件路径：\(audioPath)")
            } catch {
                print("音频播放器初始化失败: \(error.localizedDescription)")
            }
        } else {
            print("找不到音频文件，路径：\(audioPath)")
        }
    }

    @objc private func playButtonTapped() {
        if let player = audioPlayer {
            if player.isPlaying {
                player.pause()
                playButton.setTitle("播放音樂", for: .normal)
            } else {
                player.play()
                playButton.setTitle("暫停", for: .normal)
            }
        }
    }

    // MARK: - UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return cityStatuses.count
    }
    
    // MARK: - UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return cityStatuses[row].city
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateResultLabel(for: row)
    }
}

