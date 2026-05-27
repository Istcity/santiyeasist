import PDFKit
import UIKit

enum CostReportPDFService {
  private static let brandName = "Şantiye Asist"

  @MainActor
  static func share(result: CostCalculationResult) {
    guard let data = buildPDFData(result: result) else { return }
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("santiye_asist_maliyet.pdf")
    try? data.write(to: url)

    let controller = UIActivityViewController(
      activityItems: [url],
      applicationActivities: nil
    )
    guard let presenter = topViewController() else { return }
    if let popover = controller.popoverPresentationController {
      popover.sourceView = presenter.view
      popover.sourceRect = CGRect(
        x: presenter.view.bounds.midX,
        y: presenter.view.bounds.midY,
        width: 1,
        height: 1
      )
    }
    presenter.present(controller, animated: true)
  }

  static func buildPDFData(result: CostCalculationResult) -> Data? {
    let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

    return renderer.pdfData { context in
      context.beginPage()
      let attrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 18),
      ]
      let body: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 11),
      ]
      let footerAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 10, weight: .medium),
        .foregroundColor: UIColor(red: 0.04, green: 0.12, blue: 0.23, alpha: 0.65),
      ]

      var y: CGFloat = 40
      ("Maliyet Raporu — \(result.projectName)" as NSString).draw(
        at: CGPoint(x: 40, y: y),
        withAttributes: attrs
      )
      y += 36

      let header = """
      Arsa: \(Int(result.landAreaM2)) m² | Oturum: \(Int(result.footprintM2)) m²
      Kat: \(result.floorCount) | Toplam alan: \(Int(result.totalBuildAreaM2)) m²

      """
      (header as NSString).draw(
        at: CGPoint(x: 40, y: y),
        withAttributes: body
      )
      y += 60

      for item in result.lineItems {
        let line = "\(item.label) — \(MoneyFormatter.formatAmount(item.quantity)) \(item.unit) × \(MoneyFormatter.formatTRY(item.unitPriceTry)) = \(MoneyFormatter.formatTRY(item.totalTry))\n"
        (line as NSString).draw(at: CGPoint(x: 40, y: y), withAttributes: body)
        y += 18
        if y > 720 { break }
      }

      for item in result.manualItems where item.amountTry > 0 {
        let name = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let label = name.isEmpty ? "Ek kalem" : name
        let line = "\(label) — \(MoneyFormatter.formatTRY(item.amountTry))\n"
        (line as NSString).draw(at: CGPoint(x: 40, y: y), withAttributes: body)
        y += 18
        if y > 720 { break }
      }

      if result.kdvAmount > 0 {
        let kdvLine = "KDV: \(MoneyFormatter.formatTRY(result.kdvAmount))\n"
        (kdvLine as NSString).draw(at: CGPoint(x: 40, y: y), withAttributes: body)
        y += 18
      }
      if result.karMarjiAmount > 0 {
        let karLine = "Kar Marjı: \(MoneyFormatter.formatTRY(result.karMarjiAmount))\n"
        (karLine as NSString).draw(at: CGPoint(x: 40, y: y), withAttributes: body)
        y += 18
      }

      y += 12
      let total = """
      TOPLAM: \(MoneyFormatter.formatTRY(result.grandTotalTry))
      m² birim: \(MoneyFormatter.formatTRY(result.costPerM2Try))/m²
      """
      (total as NSString).draw(
        at: CGPoint(x: 40, y: y),
        withAttributes: attrs
      )

      drawFooter(brandName, pageRect: pageRect, attributes: footerAttrs)
    }
  }

  private static func drawFooter(
    _ text: String,
    pageRect: CGRect,
    attributes: [NSAttributedString.Key: Any]
  ) {
    let footerY = pageRect.height - 36
    let size = (text as NSString).size(withAttributes: attributes)
    let x = (pageRect.width - size.width) / 2
    (text as NSString).draw(at: CGPoint(x: x, y: footerY), withAttributes: attributes)

    let lineY = footerY - 8
    let path = UIBezierPath()
    path.move(to: CGPoint(x: 40, y: lineY))
    path.addLine(to: CGPoint(x: pageRect.width - 40, y: lineY))
    UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 0.45).setStroke()
    path.lineWidth = 0.5
    path.stroke()
  }

  @MainActor
  static func shareHakedisPDF(projectName: String, items: [HakedisItem]) {
    let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
    let data = renderer.pdfData { context in
      context.beginPage()
      let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 18)]
      let body: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11)]
      let footerAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 10, weight: .medium),
        .foregroundColor: UIColor(red: 0.04, green: 0.12, blue: 0.23, alpha: 0.65),
      ]

      var y: CGFloat = 40
      ("Hakediş Raporu — \(projectName)" as NSString).draw(at: CGPoint(x: 40, y: y), withAttributes: titleAttrs)
      y += 36

      let totalEstimated = items.reduce(0) { $0 + $1.estimatedCostTry }
      let totalCompleted = items.reduce(0) { $0 + $1.completedCostTry }
      let overallPercent = totalEstimated > 0 ? totalCompleted / totalEstimated * 100 : 0
      let summary = "Genel İlerleme: %\(String(format: "%.0f", overallPercent)) | Toplam: \(MoneyFormatter.formatTRY(totalCompleted)) / \(MoneyFormatter.formatTRY(totalEstimated))\n"
      (summary as NSString).draw(at: CGPoint(x: 40, y: y), withAttributes: body)
      y += 30

      for item in items {
        let line = "\(item.name) — %\(String(format: "%.0f", item.completionPercent)) | \(MoneyFormatter.formatTRY(item.completedCostTry)) / \(MoneyFormatter.formatTRY(item.estimatedCostTry))\n"
        (line as NSString).draw(at: CGPoint(x: 40, y: y), withAttributes: body)
        y += 18
        if y > 720 { break }
      }

      drawFooter(brandName, pageRect: pageRect, attributes: footerAttrs)
    }

    let url = FileManager.default.temporaryDirectory.appendingPathComponent("santiye_asist_hakedis.pdf")
    try? data.write(to: url)
    guard let presenter = topViewController() else { return }
    let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    if let popover = controller.popoverPresentationController {
      popover.sourceView = presenter.view
      popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
    }
    presenter.present(controller, animated: true)
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
