# Stack Guide — スタック別実装ガイド

## スタック選定マトリクス

| プロジェクト | 推奨スタック | 理由 |
|---|---|---|
| Next.js Web App | Next.js + Tailwind + shadcn/ui | フルスタック、AppRouter対応、コンポーネント充実 |
| Vite SPA | React + Vite + Tailwind + shadcn/ui | 軽量・高速ビルド |
| LP / 静的サイト | Astro + Tailwind | SSG最適、画像最適化、軽量 |
| モバイル (iOS/Android) | Expo (React Native) + NativeWind | Tailwind互換、クロスプラットフォーム |
| Vue プロジェクト | Vue 3 + Nuxt + Tailwind + Radix Vue | エコシステム |
| Svelte プロジェクト | SvelteKit + Tailwind + Skeleton UI | 超軽量 |

---

## Next.js + Tailwind + shadcn/ui (推奨)

### セットアップ
```bash
# 新規プロジェクト
npx create-next-app@latest my-app --typescript --tailwind --eslint --app --src-dir

# shadcn/ui 初期化
cd my-app
npx shadcn@latest init

# コンポーネント追加（必要なものを都度）
npx shadcn@latest add button card input label select
npx shadcn@latest add dialog sheet toast tabs accordion
npx shadcn@latest add table badge skeleton avatar
npx shadcn@latest add dropdown-menu context-menu
npx shadcn@latest add form  # React Hook Form + Zod 統合

# アニメーション
npm install tailwindcss-animate class-variance-authority clsx tailwind-merge
```

### フォント設定 (next/font)
```typescript
// app/layout.tsx
import { Inter } from 'next/font/google'

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-sans',
  display: 'swap',
})

// 日本語追加する場合
import { BIZ_UDGothic } from 'next/font/google'
const bizUDGothic = BIZ_UDGothic({
  weight: ['400', '700'],
  subsets: ['latin'],
  variable: '--font-ja',
  display: 'swap',
})

export default function RootLayout({ children }) {
  return (
    <html lang="ja" suppressHydrationWarning>
      <body className={`${inter.variable} ${bizUDGothic.variable} font-sans`}>
        {children}
      </body>
    </html>
  )
}
```

### ダークモード設定
```typescript
// next-themes を使う
npm install next-themes

// app/layout.tsx に ThemeProvider 追加
import { ThemeProvider } from 'next-themes'

<ThemeProvider attribute="class" defaultTheme="system" enableSystem>
  {children}
</ThemeProvider>
```

### cva でコンポーネントバリアント
```typescript
// components/ui/button.tsx の例
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva(
  // base
  'inline-flex items-center justify-center gap-2 rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        outline: 'border border-input bg-background hover:bg-accent hover:text-accent-foreground',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        link: 'text-primary underline-offset-4 hover:underline',
      },
      size: {
        sm: 'h-8 px-3 text-xs',
        default: 'h-10 px-4 py-2',
        lg: 'h-11 px-8',
        icon: 'h-10 w-10',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
)
```

### フォームバリデーション (React Hook Form + Zod)
```typescript
// shadcn Form コンポーネントと組み合わせ
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const schema = z.object({
  email: z.string().email('有効なメールアドレスを入力してください'),
  password: z.string().min(8, 'パスワードは8文字以上で入力してください'),
})

type FormData = z.infer<typeof schema>

export function LoginForm() {
  const form = useForm<FormData>({ resolver: zodResolver(schema) })

  return (
    <Form {...form}>
      <FormField
        control={form.control}
        name="email"
        render={({ field }) => (
          <FormItem>
            <FormLabel>メールアドレス</FormLabel>
            <FormControl>
              <Input type="email" autoComplete="email" {...field} />
            </FormControl>
            <FormMessage />  {/* zodのエラーが自動表示 */}
          </FormItem>
        )}
      />
    </Form>
  )
}
```

---

## Astro + Tailwind (LP / 静的サイト)

```bash
npm create astro@latest -- --template minimal
npx astro add tailwind
npx astro add react  # インタラクティブな部分はReact island

# shadcn/ui をAstroで使う
npm install @astrojs/react
# shadcn コンポーネントをそのままimportして使用可
```

### Astro特有の最適化
```astro
---
// 静的画像の最適化
import { Image } from 'astro:assets'
import heroImage from '../assets/hero.png'
---
<Image src={heroImage} alt="Hero" widths={[640, 1280, 1920]} />
```

---

## Expo (React Native) + NativeWind

```bash
npx create-expo-app my-app -t expo-template-blank-typescript
cd my-app
npx expo install nativewind tailwindcss
npx expo install @expo/vector-icons

# セットアップ: babel.config.js と tailwind.config.js を設定
```

### モバイル特有の注意
```typescript
// タッチターゲット確保
import { TouchableOpacity } from 'react-native'

// StyleSheet より NativeWind のclassNameを優先
<TouchableOpacity
  className="min-h-[44px] min-w-[44px] items-center justify-center px-4"
  accessible={true}
  accessibilityLabel="メニューを開く"
  accessibilityRole="button"
>
```

---

## ライブラリバージョン固定 (2025年基準)

```json
{
  "dependencies": {
    "next": "^15.0.0",
    "react": "^19.0.0",
    "tailwindcss": "^3.4.0",
    "@radix-ui/react-*": "^1.0.0",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.0.0",
    "tailwind-merge": "^2.0.0",
    "tailwindcss-animate": "^1.0.7",
    "next-themes": "^0.3.0",
    "react-hook-form": "^7.0.0",
    "@hookform/resolvers": "^3.0.0",
    "zod": "^3.0.0",
    "lucide-react": "^0.400.0"
  }
}
```

## アイコンライブラリ選定

| ライブラリ | 特徴 | 推奨シーン |
|---|---|---|
| **Lucide React** | 軽量・tree-shakable・一貫したスタイル | shadcn/ui標準 → **第一選択** |
| Heroicons | Tailwind Lab製・Solid/Outline | Tailwind UIと使う時 |
| Phosphor Icons | バリアント多数（6種） | 表現力が欲しい時 |
| Radix Icons | Radix UI同梱 | 小さめUI |

```bash
# Lucide (推奨)
npm install lucide-react

import { ArrowRight, Check, X, Search, Menu } from 'lucide-react'
<ArrowRight className="size-4" />  # size-4 = 16px
```

## Stage別 コマンドリファレンス

```bash
# Stage 1: Layout確認
# Next.js dev server
npm run dev

# Stage 2: カラー確認
# Tailwind config変更後は自動リロード

# Stage 5: コンポーネント追加
npx shadcn@latest add [component-name]

# Stage 7: アクセシビリティ確認
npx axe-core  # または Chrome DevTools Lighthouse

# Stage 8: レスポンシブ確認
# Chrome DevTools > Toggle Device Toolbar (Cmd+Shift+M)

# Stage 9: パフォーマンス確認
npm run build && npm run start  # production build
# → Chrome DevTools > Lighthouse
```
