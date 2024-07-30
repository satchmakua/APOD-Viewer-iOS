// CS 458
// Project 3

// APOD Viewer App
// This iOS app fetches and displays the Astronomy Picture of the Day (APOD) from NASA's APOD API.
// Users can view the image, title, description, and copyright notice of today's astronomical picture.
// Additionally, the app allows users to select a different date using a date picker to view pictures from other days.
// Handles network errors gracefully and informs users when a non-image content is available.

//
//  ViewController.swift
//  APODviewer
//
//  Created by satchel hamilton on 4/6/24.
//

import UIKit

class ViewController: UIViewController {
    
    var imageView = UIImageView()
    var titleLabel = UILabel()
    var descriptionLabel = UILabel()
    var copyrightLabel = UILabel()
    var datePicker = UIDatePicker()
    let formatter = DateFormatter()
    let apiKey = "29ZpelbkYscWLSnpeIUzz2hErOpMgM4dhlMfUfKW"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchAPODData(for: Date())
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.numberOfLines = 0
        view.addSubview(descriptionLabel)
        
        copyrightLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(copyrightLabel)
        
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            copyrightLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            copyrightLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            copyrightLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            datePicker.topAnchor.constraint(equalTo: copyrightLabel.bottomAnchor, constant: 20),
            datePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func dateChanged() {
        fetchAPODData(for: datePicker.date)
    }
    
    private func fetchAPODData(for date: Date) {
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        guard let url = URL(string: "https://api.nasa.gov/planetary/apod?api_key=\(apiKey)&date=\(dateString)") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self?.displayError("Fetch data failed.")
                return
            }
            do {
                let apod = try JSONDecoder().decode(APOD.self, from: data)
                DispatchQueue.main.async {
                    self?.updateUI(with: apod)
                }
            } catch {
                self?.displayError("DaTa decoding failed.")
            }
        }.resume()
    }
    
    private func updateUI(with apod: APOD) {
        titleLabel.text = apod.title
        descriptionLabel.text = apod.explanation
        
        if apod.mediaType == "image" {
            if let imageUrl = URL(string: apod.url) {
                if let imageData = try? Data(contentsOf: imageUrl) {
                    imageView.image = UIImage(data: imageData)
                }
            }
        } else {
            imageView.image = nil
            displayError("The content for selected date is not an image.")
        }
        
        copyrightLabel.text = apod.copyRight
    }
    
    private func displayError(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}


struct APOD: Codable {
    let date: String
    let explanation: String
    let title: String
    let url: String
    let mediaType: String
    let copyRight: String?
    
    enum CodingKeys: String, CodingKey {
        case date, explanation, title, url, mediaType = "media_type", copyRight = "copyright"
    }
}
