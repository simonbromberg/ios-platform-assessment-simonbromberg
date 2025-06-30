import Foundation
import SwiftUI

struct VehicleList: View {
  @Observable
  class ViewModel {
    var vehicles: [Vehicle] = []
    private var nextPage: Paging?

    private let dataProvider: DataProvider

    init(dataProvider: DataProvider) {
      self.dataProvider = dataProvider
    }

    func fetchVehicles(shouldLoadNextPage: Bool = false) async throws {
      if shouldLoadNextPage {
        let (newPageOfVehicles, paging) = try await dataProvider.getVehicles(startCursor: nextPage?.nextCursor)
        nextPage = paging
        vehicles += newPageOfVehicles
      } else {
        (vehicles, nextPage) = try await dataProvider.getVehicles(startCursor: nil)
      }
    }

    var hasMorePages: Bool {
      nextPage?.estimatedRemainingCount ?? 0 > vehicles.count
    }

    func reset() {
      nextPage = nil
      vehicles.removeAll(keepingCapacity: true)
    }
  }

  @Environment(ViewModel.self) private var viewModel

  @State private var pageLoadStart: Date = .now

  @State private var isLoading = true
  @State private var searchText = ""
  @State private var selectedVehicle: Vehicle?
  @State private var lastUpdated = Date()

  var filteredVehicles: [Vehicle] {
    if searchText.isEmpty {
      return viewModel.vehicles
    } else {
      let searchTerms = searchText.lowercased().split(separator: " ")
      return viewModel.vehicles.filter { vehicle in
        searchTerms.allSatisfy { term in
          vehicle.customName.lowercased().contains(term) ||
          vehicle.make.lowercased().contains(term) ||
          vehicle.model.lowercased().contains(term) ||
          vehicle.year.lowercased().contains(term)
        }
      }
    }
  }

  var body: some View {
    VStack {
      SearchBar(text: $searchText)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .onChange(of: searchText) {
          lastUpdated = Date()
        }
      List {
        if isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .frame(maxWidth: .infinity)
        }
        ForEach(filteredVehicles, id: \.id) { vehicle in
          NavigationLink(destination: VehicleView(vehicle: vehicle)) {
            VehicleRow(vehicle: vehicle)
          }
          .accessibilityIdentifier(AccessibilityIdentifiers.VehicleList.vehicleListItem(id: vehicle.id))
          .background(selectedVehicle?.id == vehicle.id ? Color.gray.opacity(0.1) : Color.clear)
        }
        if viewModel.hasMorePages {
          Button("Load more") {
            loadData(shouldLoadNextPage: true)
          }
        }
      }
      .refreshable {
        viewModel.reset()
        loadData()
      }
      .navigationTitle("Vehicles")
      .navigationBarTitleDisplayMode(.inline)
    }
    .onAppear {
      MetricsLogger.shared.logPageLoad(page: "VehicleList", start: pageLoadStart)
      MetricsLogger.shared.save()
      loadData()
    }
  }

  func loadData(shouldLoadNextPage: Bool = false) {
    isLoading = true
    Task {
      do {
        try await viewModel.fetchVehicles(shouldLoadNextPage: shouldLoadNextPage)
      } catch {
        // TODO: error handling
        print(error)
      }
      isLoading = false
    }
  }
}

struct VehicleRow: View {
  let vehicle: Vehicle

  var body: some View {
    HStack {
      Image(systemName: "car")
        .imageScale(.large)
        .foregroundColor(.gray)
        .frame(width: 50, height: 50)

      VStack(alignment: .leading) {
        Text(vehicle.customName)
          .font(.headline)
          .lineLimit(1)

        HStack {
          Text(vehicle.year)
          Text(vehicle.make)
          Text(vehicle.model)
        }
        .font(.subheadline)
        .foregroundColor(.secondary)

        HStack {
          Circle()
            .frame(width: 10, height: 10)
            .foregroundColor(vehicle.status == "Active" ? .green : .red) // TODO: use status color from API
          Text(vehicle.status)
          Text("\u{2022}")
          Text(vehicle.location)
        }
        .font(.caption)
        .foregroundColor(.secondary)
      }
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  NavigationView {
    VehicleList()
      .environment(
        VehicleList.ViewModel(
          dataProvider: SampleDataProvider()
        )
      )
  }
}
