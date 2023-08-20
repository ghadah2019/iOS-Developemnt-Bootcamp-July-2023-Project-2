//
//  ContentView.swift
//  weatherAPI
//
//  Created by Ghada Al on 03/02/1445 AH.
//

import SwiftUI
import Foundation

struct WeatherData: Codable {
    let coord: Coord
    let weather: [Weather]
    let base: String
    let main: Main
    let visibility: Int
    let wind: Wind
    let clouds: Clouds
    let dt: Int
    let sys: Sys
    let timezone: Int
    let id: Int
    let name: String
    let cod: Int
}

struct Coord: Codable {
    let lon: Double
    let lat: Double
}

struct Weather: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct Main: Codable {
    let temp: Double
    let feels_like: Double
    let temp_min: Double
    let temp_max: Double
    let pressure: Int
    let humidity: Int
}

struct Wind: Codable {
    let speed: Double
    let deg: Int
}

struct Clouds: Codable {
    let all: Int
}

struct Sys: Codable {
    let type: Int
    let id: Int
    let country: String
    let sunrise: Int
    let sunset: Int
}


enum TemperatureUnit: String, CaseIterable {
    case celsius = "Celsius"
    case fahrenheit = "Fahrenheit"
    
    var unit: UnitTemperature {
        switch self {
        case .celsius:
            return .celsius
        case .fahrenheit:
            return .fahrenheit
        }
    }
    
    func temperatureString(_ temperature: Double) -> String {
        let measurement = Measurement(value: temperature, unit: UnitTemperature.kelvin)
        let convertedMeasurement = measurement.converted(to: unit)
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.numberStyle = .decimal
        formatter.unitOptions = .providedUnit
        return formatter.string(from: convertedMeasurement)
    }
}

struct WeatherDetailView: View {
    let weatherData: WeatherData
    @State private var temperatureUnit: TemperatureUnit = .celsius
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Weather Details")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 10) {
                HStack {
                    Text("Temperature:")
                        .font(.headline)
                    Spacer()
                    Text("\(temperatureUnit.temperatureString(weatherData.main.temp))")
                }
                
                HStack {
                    Text("Humidity:")
                        .font(.headline)
                    Spacer()
                    Text("\(weatherData.main.humidity)%")
                }
                
                HStack {
                    Text("Wind Speed:")
                        .font(.headline)
                    Spacer()
                    Text("\(formattedSpeed(weatherData.wind.speed))")
                }
                
                HStack {
                    Text("Weather Condition:")
                        .font(.headline)
                    Spacer()
                    Text("\(weatherData.weather.first?.main ?? "")")
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
    
    func formattedSpeed(_ speed: Double) -> String {
        let measurement = Measurement(value: speed, unit: UnitSpeed.metersPerSecond)
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.numberStyle = .decimal
        formatter.unitOptions = .naturalScale
        return formatter.string(from: measurement)
    }
}

struct ContentView: View {
    @State private var city: String = ""
    @State private var weatherData: WeatherData?
    @State private var errorMessage: String = ""
    @State private var showingWeatherDetails = false
    @State private var temperatureUnit: TemperatureUnit = .celsius

    @State private var searchHistory: [String] = UserDefaults.standard.stringArray(forKey: "SearchHistory") ?? []

    init() {
        if let encodedData = UserDefaults.standard.data(forKey: "WeatherData"),
           let decodedData = try? JSONDecoder().decode(WeatherData.self, from: encodedData) {
            self.weatherData = decodedData
        }

        if let savedHistory = UserDefaults.standard.array(forKey: "SearchHistory") as? [String] {
            self.searchHistory = savedHistory
        }
    }
    
    var body: some View {
        VStack {
            Text("Weather App")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
                .foregroundColor(.purple)
            
            TextField("Enter city", text: $city)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            
            Picker("Temperature Unit", selection: $temperatureUnit) {
                ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                    Text(unit.rawValue)
                }
            }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            
            Button(action: {
                searchWeather()
            }) {
                Text("Search")
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 40)
                    .background(Color.purple)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
            
            if let weatherData = weatherData {
                VStack {
                    Text("Temperature: \(temperatureUnit.temperatureString(weatherData.main.temp))")
                    Text("Humidity: \(weatherData.main.humidity)%")
                    Text("Wind Speed: \(formattedSpeed(weatherData.wind.speed))")
                    Text("Weather Condition: \(weatherData.weather.first?.main ?? "")")
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                
                Button(action: {
                    showingWeatherDetails = true
                }) {
                    Text("Show Details")
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 40)
                        .background(Color.purple)
                        .cornerRadius(10)
                }
                .padding(.bottom, 20)
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
            }
            
            VStack(alignment: .leading) {
                Text("Search History:")
                    .font(.headline)
                
                List(searchHistory, id: \.self) { city in
                    Text(city)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .sheet(isPresented: $showingWeatherDetails) {
                if let weatherData = weatherData {
                    WeatherDetailView(weatherData: weatherData)
                }
            }
        }

        func searchWeather() {
            guard !city.isEmpty else {
                errorMessage = "Please enter a city."
                return
            }

            let apiKey = "8427462314d9f1b3620cb3a73b67790f"
            let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(apiKey)"

            guard let url = URL(string: urlString) else {
                errorMessage = "Invalid URL."
                return
            }

            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    errorMessage = "Invalid response."
                    return
                }

                guard let data = data else {
                    errorMessage = "No data received."
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let weatherData = try decoder.decode(WeatherData.self, from: data)

                    DispatchQueue.main.async {
                        self.weatherData = weatherData
                        self.errorMessage = ""

                        if !searchHistory.contains(city) {
                            searchHistory.append(city)
                        }

                        if let encodedData = try? JSONEncoder().encode(weatherData) {
                            UserDefaults.standard.set(encodedData, forKey: "WeatherData")
                        }

                        UserDefaults.standard.set(searchHistory, forKey: "SearchHistory")
                    }
                } catch {
                    DispatchQueue.main.async {
                        errorMessage = error.localizedDescription
                    }
                }
            }

            task.resume()
        }
    
    func formattedSpeed(_ speed: Double) -> String {
        let measurement = Measurement(value: speed, unit: UnitSpeed.metersPerSecond)
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.numberStyle = .decimal
        formatter.unitOptions = .naturalScale
        return formatter.string(from: measurement)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
