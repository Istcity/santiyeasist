import SwiftUI

struct ExtendedMaterialsCard: View {
  @ObservedObject private var store = ExtendedMaterialStore.shared
  @State private var selectedCategory: ExtendedMaterial.MaterialCategory?
  @State private var isExpanded = false

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
            HStack {
              Image(systemName: material.category.icon)
                .foregroundStyle(AppTheme.gold)
                .frame(width: 24)
              VStack(alignment: .leading, spacing: 2) {
                Text(material.name)
                  .font(.subheadline.weight(.medium))
                  .foregroundStyle(AppTheme.navy)
                Text(material.unit)
                  .font(.caption2)
                  .foregroundStyle(AppTheme.warmGray)
              }
              Spacer()
              Text(MoneyFormatter.formatTRY(material.priceTry))
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.charcoal)
            }
            .padding(.vertical, 4)
          }
        } else {
          Text("\(store.materials.count) malzeme kaydı")
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
