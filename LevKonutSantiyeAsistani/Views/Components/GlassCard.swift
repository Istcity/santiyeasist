import SwiftUI

struct GlassCard<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .padding(20)
      .background {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
          .fill(.ultraThinMaterial)
          .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
              .fill(AppTheme.cardFill)
          )
          .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
              .stroke(AppTheme.cardStroke, lineWidth: 1.2)
          }
          .shadow(color: AppTheme.cardShadow, radius: 20, y: 10)
      }
  }
}

/// Uyarı / dikkat kartı — altın yerine kırmızı vurgu.
struct AttentionGlassCard<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .padding(20)
      .background {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
          .fill(.ultraThinMaterial)
          .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
              .fill(AppTheme.alertRedFill.opacity(0.85))
          )
          .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
              .stroke(AppTheme.alertCardStroke, lineWidth: 1.6)
          }
          .shadow(color: AppTheme.alertRed.opacity(0.18), radius: 20, y: 10)
      }
  }
}

struct GlassInsetTile<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .padding(14)
      .background {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
          .fill(Color.white.opacity(0.42))
          .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
              .stroke(Color.white.opacity(0.55), lineWidth: 1)
          }
      }
  }
}

struct CircularGaugeView: View {
  let progress: Double
  let lineWidth: CGFloat
  let accent: Color

  init(progress: Double, lineWidth: CGFloat = 10, accent: Color = AppTheme.gold) {
    self.progress = min(max(progress, 0), 1)
    self.lineWidth = lineWidth
    self.accent = accent
  }

  var body: some View {
    ZStack {
      Circle()
        .stroke(AppTheme.navy.opacity(0.08), lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: progress)
        .stroke(
          accent,
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
    }
  }
}

struct GoldProgressBar: View {
  let progress: Double

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        Capsule().fill(AppTheme.navy.opacity(0.08))
        Capsule()
          .fill(AppTheme.gold)
          .frame(width: geo.size.width * min(max(progress, 0), 1))
      }
    }
    .frame(height: 6)
  }
}

/// Şantiye Asist marka logosu — uygulama içi ve AppIcon ile aynı tasarım.
/// Sarı bina silueti + beyaz detaylar, lacivert arka plan.
struct SantiyeAsistLogoMark: View {
  var size: CGFloat = 44

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
        .fill(
          LinearGradient(
            colors: [AppTheme.navyLight, AppTheme.navy],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay {
          RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .stroke(AppTheme.gold.opacity(0.85), lineWidth: max(1, size * 0.04))
        }

      VStack(spacing: size * 0.06) {
        HStack(alignment: .bottom, spacing: size * 0.05) {
          RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
            .fill(AppTheme.gold)
            .frame(width: size * 0.14, height: size * 0.22)
          RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
            .fill(AppTheme.gold)
            .frame(width: size * 0.18, height: size * 0.30)
          RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
            .fill(AppTheme.gold.opacity(0.9))
            .frame(width: size * 0.14, height: size * 0.18)
        }
        RoundedRectangle(cornerRadius: 1, style: .continuous)
          .fill(Color.white)
          .frame(width: size * 0.52, height: size * 0.05)
      }
      .offset(y: size * 0.02)
    }
    .frame(width: size, height: size)
    .shadow(color: AppTheme.cardShadow, radius: size * 0.12, y: size * 0.06)
  }
}

struct AnimatedConstructionTruck: View {
  @State private var travelProgress: CGFloat = 1
  @State private var didAnimate = false

  var body: some View {
    GeometryReader { geo in
      let lane = max(geo.size.width - 26, 0)
      Image(systemName: "box.truck.fill")
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(AppTheme.gold)
        .scaleEffect(x: -1, y: 1)
        .offset(x: travelProgress * lane, y: 0)
        .onAppear {
          guard !didAnimate else { return }
          didAnimate = true
          withAnimation(.easeInOut(duration: 2.4)) {
            travelProgress = 0
          }
        }
    }
    .frame(height: 22)
  }
}

struct ConstructionHardHatIcon: View {
  var size: CGFloat = 32

  var body: some View {
    ConstructionHardHatShape()
      .fill(
        LinearGradient(
          colors: [AppTheme.gold, AppTheme.goldMuted],
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .frame(width: size, height: size * 0.82)
      .shadow(color: AppTheme.cardShadow, radius: 2, y: 1)
  }
}

struct StackedBricksIcon: View {
  var body: some View {
    VStack(spacing: -2) {
      HStack(spacing: 1) {
        brick
        brick.offset(x: 3)
      }
      HStack(spacing: 1) {
        brick
        brick.offset(x: 3)
        brick
      }
      HStack(spacing: 1) {
        brick
        brick.offset(x: 3)
      }
    }
  }

  private var brick: some View {
    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
      .fill(
        LinearGradient(
          colors: [AppTheme.gold, AppTheme.goldMuted],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .frame(width: 13, height: 5)
      .overlay {
        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
          .stroke(AppTheme.navy.opacity(0.18), lineWidth: 0.5)
      }
  }
}

struct ConstructionHardHatShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let w = rect.width
    let h = rect.height

    path.move(to: CGPoint(x: w * 0.18, y: h * 0.58))
    path.addQuadCurve(
      to: CGPoint(x: w * 0.82, y: h * 0.58),
      control: CGPoint(x: w * 0.5, y: h * 0.08)
    )
    path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.66))
    path.addLine(to: CGPoint(x: w * 0.12, y: h * 0.66))
    path.closeSubpath()

    let brim = CGRect(x: w * 0.06, y: h * 0.6, width: w * 0.88, height: h * 0.16)
    path.addRoundedRect(in: brim, cornerSize: CGSize(width: 2, height: 2))

    return path
  }
}
