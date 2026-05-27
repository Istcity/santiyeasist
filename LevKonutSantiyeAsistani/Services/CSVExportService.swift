import Foundation
import UIKit

enum CSVExportService {
  @MainActor
  static func shareCSV(result: CostCalculationResult) {
    let csv = buildCSV(result: result)
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("santiye_asist_maliyet.csv")
    try? csv.write(to: url, atomically: true, encoding: .utf8)

    guard let presenter = topViewController() else { return }
    let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    if let popover = controller.popoverPresentationController {
      popover.sourceView = presenter.view
      popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
    }
    presenter.present(controller, animated: true)
  }

  static func buildCSV(result: CostCalculationResult) -> String {
    var lines: [String] = []
    lines.append("Şantiye Asist - Maliyet Raporu")
    lines.append("Proje;\(result.projectName)")
    lines.append("Arsa (m²);\(formatted(result.landAreaM2))")
    lines.append("Oturum (m²);\(formatted(result.footprintM2))")
    lines.append("Kat Sayısı;\(result.floorCount)")
    lines.append("Toplam Alan (m²);\(formatted(result.totalBuildAreaM2))")
    lines.append("")
    lines.append("Kalem;Miktar;Birim;Birim Fiyat (₺);Toplam (₺)")

    for item in result.lineItems {
      lines.append("\(item.label);\(formatted(item.quantity));\(item.unit);\(formatted(item.unitPriceTry));\(formatted(item.totalTry))")
    }

    for item in result.manualItems where item.amountTry > 0 {
      let name = item.title.trimmingCharacters(in: .whitespaces).isEmpty ? "Ek kalem" : item.title
      lines.append("\(name);;;;\(formatted(item.amountTry))")
    }

    lines.append("")
    lines.append("TOPLAM;;\(formatted(result.grandTotalTry))")
    lines.append("m² Birim Fiyat;;\(formatted(result.costPerM2Try))")

    return lines.joined(separator: "\n")
  }

  private static func formatted(_ value: Double) -> String {
    String(format: "%.2f", value).replacingOccurrences(of: ".", with: ",")
  }

  @MainActor
  private static func topViewController() -> UIViewController? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .rootViewController
  }
}
