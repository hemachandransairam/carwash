import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:mix/mix.dart";

// Color Tokens
enum AppColorTokens {
  background("background"),
  primary("primary"),
  secondary("secondary"),
  error("error");

  final String name;
  const AppColorTokens(this.name);
  ColorToken get token => ColorToken(name);
  ColorToken call() => token;
}

// Text Style Tokens
enum AppTextStyleTokens {
  h1("h1"),
  h2("h2"),
  body("body");

  final String name;
  const AppTextStyleTokens(this.name);
  TextStyleToken get token => TextStyleToken(name);
  TextStyleToken call() => token;
}

// Space Tokens
enum AppSpaceTokens {
  small("small"),
  medium("medium"),
  large("large");

  final String name;
  const AppSpaceTokens(this.name);
  SpaceToken get token => SpaceToken(name);
  SpaceToken call() => token;
}

// Radius Tokens
enum AppRadiusTokens {
  small("small"),
  medium("medium"),
  large("large");

  final String name;
  const AppRadiusTokens(this.name);
  RadiusToken get token => RadiusToken(name);
  RadiusToken call() => token;
}

class LightTheme {
  static Map<ColorToken, Color> get colors => {
    AppColorTokens.background.token: const Color(0xFFFFFFFF),
    AppColorTokens.primary.token: const Color(0xFF6200EE),
    AppColorTokens.secondary.token: const Color(0xFF03DAC6),
    AppColorTokens.error.token: const Color(0xFFB00020),
  };

  static Map<TextStyleToken, TextStyle> get textStyles => {
    AppTextStyleTokens.h1.token: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    AppTextStyleTokens.h2.token: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
    AppTextStyleTokens.body.token: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.normal,
    ),
  };

  static Map<SpaceToken, double> get spaces => {
    AppSpaceTokens.small.token: 8,
    AppSpaceTokens.medium.token: 16,
    AppSpaceTokens.large.token: 24,
  };

  static Map<RadiusToken, Radius> get radii => {
    AppRadiusTokens.small.token: const Radius.circular(4),
    AppRadiusTokens.medium.token: const Radius.circular(8),
    AppRadiusTokens.large.token: const Radius.circular(16),
  };

  static MixThemeData get theme => MixThemeData(
    colors: colors,
    textStyles: textStyles,
    spaces: spaces,
    radii: radii,
  );
}
