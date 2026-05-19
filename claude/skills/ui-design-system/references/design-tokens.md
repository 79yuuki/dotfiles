# Design Tokens — 完全定義リファレンス

SKILL.mdの基本雛形を拡張した完全版デザイントークン。
shadcn/ui の CSS変数スキームをベースにしている。

## globals.css 完全テンプレート

```css
@layer base {
  :root {
    /* ============================
       Background / Surface
    ============================ */
    --background: 0 0% 100%;            /* #FFFFFF */
    --foreground: 222.2 84% 4.9%;       /* #0A0A0A */

    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;

    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;

    /* ============================
       Brand Colors
    ============================ */
    --primary: 222.2 47.4% 11.2%;       /* 例: deep navy */
    --primary-foreground: 210 40% 98%;

    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;

    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;

    /* ============================
       Semantic
    ============================ */
    --destructive: 0 84.2% 60.2%;       /* red */
    --destructive-foreground: 210 40% 98%;

    --warning: 38 92% 50%;              /* amber */
    --warning-foreground: 0 0% 100%;

    --success: 142 71% 45%;             /* green */
    --success-foreground: 0 0% 100%;

    --info: 199 89% 48%;                /* blue */
    --info-foreground: 0 0% 100%;

    /* ============================
       UI Parts
    ============================ */
    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;

    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 222.2 84% 4.9%;            /* フォーカスリング色 */

    /* ============================
       Border Radius
    ============================ */
    --radius-sm: 0.25rem;   /* 4px */
    --radius: 0.5rem;       /* 8px */
    --radius-md: 0.75rem;   /* 12px */
    --radius-lg: 1rem;      /* 16px */
    --radius-xl: 1.5rem;    /* 24px */
    --radius-full: 9999px;

    /* shadcn互換 */
    --radius: 0.5rem;

    /* ============================
       Shadow
    ============================ */
    --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
    --shadow: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
    --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
    --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
    --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);

    /* ============================
       Spacing (4px grid)
    ============================ */
    --space-1: 0.25rem;
    --space-2: 0.5rem;
    --space-3: 0.75rem;
    --space-4: 1rem;
    --space-5: 1.25rem;
    --space-6: 1.5rem;
    --space-8: 2rem;
    --space-10: 2.5rem;
    --space-12: 3rem;
    --space-16: 4rem;
    --space-20: 5rem;
    --space-24: 6rem;
    --space-32: 8rem;

    /* ============================
       Typography
    ============================ */
    --font-sans: 'Inter', system-ui, -apple-system, sans-serif;
    --font-mono: 'JetBrains Mono', 'Fira Code', monospace;
    --font-ja: 'BIZ UDGothic', 'Hiragino Sans', 'Meiryo', sans-serif;

    /* ============================
       Z-index layers
    ============================ */
    --z-base: 0;
    --z-raised: 10;
    --z-dropdown: 100;
    --z-sticky: 200;
    --z-overlay: 300;
    --z-modal: 400;
    --z-popover: 500;
    --z-toast: 600;
    --z-tooltip: 700;

    /* ============================
       Animation
    ============================ */
    --duration-instant: 50ms;
    --duration-fast: 150ms;
    --duration-normal: 250ms;
    --duration-slow: 400ms;
    --ease-out: cubic-bezier(0, 0, 0.2, 1);
    --ease-in: cubic-bezier(0.4, 0, 1, 1);
    --ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
    --ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;

    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;

    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;

    --primary: 210 40% 98%;
    --primary-foreground: 222.2 47.4% 11.2%;

    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;

    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;

    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;

    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;

    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 212.7 26.8% 83.9%;
  }
}
```

## Tailwind Config 完全テンプレート

```typescript
// tailwind.config.ts
import type { Config } from 'tailwindcss'

const config: Config = {
  darkMode: ['class'],
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    container: {
      center: true,
      padding: {
        DEFAULT: '1rem',
        sm: '2rem',
        lg: '3rem',
        xl: '4rem',
      },
      screens: { '2xl': '1400px' },
    },
    extend: {
      colors: {
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        success: {
          DEFAULT: 'hsl(var(--success))',
          foreground: 'hsl(var(--success-foreground))',
        },
        warning: {
          DEFAULT: 'hsl(var(--warning))',
          foreground: 'hsl(var(--warning-foreground))',
        },
      },
      borderRadius: {
        sm: 'var(--radius-sm)',
        DEFAULT: 'var(--radius)',
        md: 'var(--radius-md)',
        lg: 'var(--radius-lg)',
        xl: 'var(--radius-xl)',
      },
      fontFamily: {
        sans: ['var(--font-sans)'],
        mono: ['var(--font-mono)'],
        ja: ['var(--font-ja)'],
      },
      // animationsは 06-interaction.md を参照
    },
  },
  plugins: [require('tailwindcss-animate')],
}

export default config
```

## トークン更新ルール

1. `globals.css` の `:root` / `.dark` を更新
2. `tailwind.config.ts` に反映
3. Stage 2 (Color) / Stage 3 (Typography) の変更時に必ず両方更新
4. コンポーネントは常にセマンティック変数 (`text-foreground`, `bg-background`) を使い、ハードコードしない
