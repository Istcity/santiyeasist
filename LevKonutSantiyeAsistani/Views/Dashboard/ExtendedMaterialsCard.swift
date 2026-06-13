import SwiftUI

struct ExtendedMaterialsCard: View {
  @ObservedObject private var store = ExtendedMaterialStore.shared
  @State private var selectedCategory: ExtendedMaterial.MaterialCategory?
  @State private var isExpanded = false
  @State private var editingMaterialID: String?

  private var filtered: [ExtendedMaterial] {
    if let cat = selectedCategory {
      return store.materials.filter { $0.category == cat }
    }
    return store.materials
  }

  var body: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 14) {
        HStack {
          Text("Malzeme Fiyatları")
            .font(.headline)
            .foregroundStyle(AppTheme.navy)
          Image(systemName: "shippingbox.fill")
            .foregroundStyle(AppTheme.gold)
          Spacer()
          Text("Dokunarak düzenle")
            .font(.caption2)
            .foregroundStyle(AppTheme.warmGray)
          Button {
            withAnimation { isExpanded.toggle() }
          } label: {
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
              .foregroundStyle(AppTheme.gold)
          }
          .buttonStyle(.plain)
        }

        if isExpanded {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
              categoryChip(nil, label: "Tümü")
              ForEach(ExtendedMaterial.MaterialCategory.allCases) { cat in
                categoryChip(cat, label: cat.rawValue)
              }
            }
          }

          ForEach(filtered) { material in
            ExtendedMaterialPriceRow(
              material: material,
              isManual: store.isManualOverride(id: material.id),
              isEditing: editingMaterialID == material.id,
              onStartEdit: { editingMaterialID = material.id },
              onCommit: { newPrice in
                store.updatePrice(id: material.id, newPrice: newPrice)
                editingMaterialID = nil
              },
              onCancel: { editingMaterialID = nil },
              onResetToLive: {
                store.clearManualOverride(id: material.id)
                editingMaterialID = nil
              }
            )
          }
        } else {
          Text("\(store.materials.count) malzeme • canlı güncelleme + manuel düzenleme")
            .font(.caption)
            .foregroundStyle(AppTheme.warmGray)
        }
      }
    }
  }

  private func categoryChip(_ category: ExtendedMaterial.MaterialCategory?, label: String) -> some View {
    let isSelected = selectedCategory == category
    return Button {
      withAnimation { selectedCategory = category }
    } label: {
      Text(label)
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
          Capsule(style: .continuous)
            .fill(isSelected ? AppTheme.gold : Color.white.opacity(0.5))
        }
        .foregroundStyle(isSelected ? .white : AppTheme.navy)
    }
    .buttonStyle(.plain)
  }
}

private struct ExtendedMaterialPriceRow: View {
  let material: ExtendedMaterial
  let isManual: Bool
  let isEditing: Bool
  let onStartEdit: () -> Void
  let onCommit: (Double) -> Void
  let onCancel: () -> Void
  let onResetToLive: () -> Void

  @State private var draft = ""

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: material.category.icon)
        .foregroundStyle(AppTheme.gold)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          Text(material.name)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.navy)
          if isManual {
            Text("Manuel")
              .font(.caption2.weight(.semibold))
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Capsule().fill(AppTheme.gold.opacity(0.25)))
              .foregroundStyle(AppTheme.navy)
          }
        }
        Text(material.unit)
          .font(.caption2)
          .foregroundStyle(AppTheme.warmGray)
      }

      Spacer()

      if isEditing {
        TextField("Fiyat", text: $draft)
          .keyboardType(.decimalPad)
          .multilineTextAlignment(.trailing)
          .frame(width: 100)
          .padding(8)
          .background(Color.white.opacity(0.7))
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

        Button("OK") {
          let parsed = MoneyFormatter.parseAmount(draft) ?? material.priceTry
          onCommit(max(0, parsed))
        }
        .font(.caption.bold())
        .foregroundStyle(AppTheme.gold)

        Button {
          onCancel()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(AppTheme.warmGray)
        }
        .buttonStyle(.plain)
      } else {
        Text(MoneyFormatter.formatTRY(material.priceTry))
          .font(.subheadline.bold())
          .foregroundStyle(isManual ? AppTheme.gold : AppTheme.charcoal)
          .onTapGesture {
            draft = MoneyFormatter.editingString(for: material.priceTry)
            onStartEdit()
          }

        if isManual {
          Button(action: onResetToLive) {
            Image(systemName: "arrow.counterclockwise")
              .font(.caption)
              .foregroundStyle(AppTheme.warmGray)
          }
          .buttonStyle(.plain)
        }
      }
    }
    .padding(.vertical, 4)
  }
}
