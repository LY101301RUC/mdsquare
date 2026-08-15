

# MarkdownDev MVP 测试文档

这是一份用于测试 MarkdownDev 的综合文档。它包含多级标题、普通段落、强调文本、表格、任务列表、引用、代码块、链接、图片占位和一些边界内容。

你可以用它检查三个区域的联动：左侧大纲是否完整，中间编辑区是否可编辑，右侧预览区是否实时更新。

## 1. 普通文本与行内样式

这是一段普通中文正文，里面包含 **加粗文本**、*斜体文本*、`行内代码`，以及一个普通链接：[OpenAI](https://openai.com)。

This paragraph mixes English and Chinese to test wrapping, punctuation, and preview rendering. Markdown should remain readable even with `inline code`, **bold**, and *italic* styles in the same sentence.

### 1.1 长段落测试

Markdown 编辑器经常会打开比较长的笔记、方案文档或会议记录。这个段落故意写得稍微长一些，用来测试编辑区和预览区的换行、滚动、字体间距以及阅读舒适度。理想状态下，文字不应该挤在一起，也不应该因为窗口大小变化而出现遮挡或奇怪的横向滚动。

### 1.2 重复标题

这一节用于测试重复标题的锚点处理。

### 1.2 重复标题

这一节的标题和上一节完全一样，用于检查预览区跳转和 slug 去重是否稳定。

## 2. 列表与任务

### 2.1 无序列表

- 产品定位：轻量、快速、专注 Markdown
- 核心界面：大纲、编辑区、实时预览
- 关键体验：打开快、写作安静、预览稳定
- 后续增强：
  - 更细腻的主题
  - 更完整的快捷键
  - 更好的导出能力

### 2.2 有序列表

1. 打开这个文件
2. 点击左侧大纲中的不同标题
3. 在编辑区修改任意一段文字
4. 观察右侧预览是否实时刷新
5. 保存后重新打开，检查内容是否保留

### 2.3 任务列表

- [x] 支持打开 UTF-8 Markdown 文件
- [x] 支持实时预览
- [x] 支持大纲跳转
- [x] 检查暗色模式
- [x] 检查保存与重新打开
- [x] 检查工具栏命令撤销

## 3. 表格

| 模块 | 期望表现 | 手工检查点 | 状态 |
| --- | --- | --- | --- |
| 大纲 | 自动提取 H1-H6 标题 | 点击标题后编辑区和预览区跳转 | 待测 |
| 编辑区 | 文本输入流畅 | 输入中文、英文、符号和换行 | 待测 |
| 预览区 | 渲染常见 Markdown | 表格、列表、代码块、引用 | 待测 |
| 保存 | 写入最新文本 | `Cmd+S` 后关闭重开 | 待测 |

| 左对齐 | 居中 | 右对齐 |
| :--- | :---: | ---: |
| apple | banana | 123 |
| short | medium text | 456.78 |
| 中文 | 混合内容 | 999 |

## 4. 引用

> 这是一段一级引用。它应该在预览区呈现为带左侧边线或缩进的引用块。

> 引用中可以包含 **加粗文本**、*斜体文本* 和 `行内代码`。

> 多行引用第一行
> 多行引用第二行
> 多行引用第三行

## 5. 代码

### 5.1 Swift 代码块

```swift
import Foundation

struct MarkdownNote {
  let title: String
  var body: String

  var wordCount: Int {
    body.split(whereSeparator: { $0.isWhitespace }).count
  }
}

let note = MarkdownNote(title: "Demo", body: "Hello MarkdownDev")
print(note.wordCount)
```

### 5.2 JavaScript 代码块

```javascript
const headings = ["Intro", "Design", "Implementation"];

for (const [index, heading] of headings.entries()) {
  console.log(`${index + 1}. ${heading}`);
}
```

### 5.3 代码块里的标题不应进入大纲

```markdown
# 这是代码块中的 H1
## 这是代码块中的 H2

这些标题看起来像 Markdown 标题，但它们在代码块里，不应该出现在左侧大纲中。
```

## 6. 链接、图片和安全边界

普通外链：[Apple Developer](https://developer.apple.com)

JavaScript 链接测试：[不应该执行的链接](javascript:alert("MarkdownDev"))

远程图片测试，预览中应被安全处理，不应真正加载远程资源：

![Remote image should be blocked](https://example.com/markdown-test-image.png)

原始 HTML 测试：

<strong>这是一段原始 HTML 加粗文本。</strong>

脚本标签测试，应该被转义或保持惰性，不应该执行：

<script>alert("This should not run")</script>

## 7. 标题层级完整性

### H3 示例

这里是 H3 下的内容。

#### H4 示例

这里是 H4 下的内容。

##### H5 示例

这里是 H5 下的内容。

###### H6 示例

这里是 H6 下的内容。左侧大纲如果展示层级缩进，可以用这一组标题检查视觉层级。

## 8. 工具栏命令测试区

你可以在下面几行选中文本，然后点击右上角工具栏测试命令：

**加粗测试文字**

*斜体测试文字*

引用测试文字

代码块测试文字第一行
代码块测试文字第二行

## 9. 滚动测试

下面用多段短文本制造一点滚动距离，方便测试大纲跳转和预览跳转。

第 1 段：MarkdownDev 应该在小窗口和大窗口下都保持三栏可用。

第 2 段：编辑区滚动时，文本输入和选择不应该明显卡顿。

第 3 段：预览区渲染应在短暂 debounce 后更新。

第 4 段：标题颜色应帮助识别结构，但不能影响正文阅读。

第 5 段：表格、列表和代码块之间的间距应该自然。

第 6 段：保存后重新打开，所有中文和符号都应该保持不变。

## 10. 结尾

如果你能看到这一节，并且从大纲点击可以准确跳到这里，说明长文档导航的基础体验是正常的。

---

最后一行：MarkdownDev 测试结束。
