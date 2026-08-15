(function () {
  "use strict";

  var allowedSchemes = new Set(["http", "https", "mailto"]);
  var md = window.markdownit({
    html: false,
    linkify: false,
    typographer: false
  }).enable(["table"]);

  md.validateLink = function () {
    return true;
  };

  function hasAllowedScheme(value) {
    if (typeof value !== "string") {
      return false;
    }

    var trimmed = value.trim();
    var match = /^([a-z][a-z0-9+.-]*):/i.exec(trimmed);
    if (!match) {
      return false;
    }

    return allowedSchemes.has(match[1].toLowerCase());
  }

  function markBlockedLink(token) {
    var hrefIndex = token.attrIndex("href");
    if (hrefIndex >= 0) {
      token.attrs.splice(hrefIndex, 1);
    }

    token.attrSet("data-blocked-link", "true");
    token.attrSet("aria-disabled", "true");
    token.attrSet("title", "Blocked unsafe link");
  }

  var defaultLinkOpen = md.renderer.rules.link_open || function (tokens, idx, options, env, self) {
    return self.renderToken(tokens, idx, options);
  };

  md.renderer.rules.link_open = function (tokens, idx, options, env, self) {
    var token = tokens[idx];
    var href = token.attrGet("href");

    if (!hasAllowedScheme(href)) {
      markBlockedLink(token);
    }

    return defaultLinkOpen(tokens, idx, options, env, self);
  };

  md.renderer.rules.image = function (tokens, idx, options, env, self) {
    var token = tokens[idx];
    var src = token.attrGet("src") || "";
    var alt = self.renderInlineAsText(token.children || [], options, env) || token.content || "image";
    if (env.localImages && env.localImages[src]) {
      return "<img src=\"" + md.utils.escapeHtml(env.localImages[src]) + "\" alt=\"" + md.utils.escapeHtml(alt) + "\">";
    }

    return "<span class=\"blocked-image\" data-blocked-image=\"true\" role=\"note\">Blocked image: "
      + md.utils.escapeHtml(alt)
      + "</span>";
  };

  function sanitizeRenderedDOM(root) {
    root.querySelectorAll("img").forEach(function (image) {
      var src = image.getAttribute("src") || "";
      if (/^data:image\/(?:png|jpeg|gif|webp);base64,/i.test(src)) {
        return;
      }

      var alt = image.getAttribute("alt") || "image";
      var replacement = document.createElement("span");
      replacement.className = "blocked-image";
      replacement.setAttribute("data-blocked-image", "true");
      replacement.setAttribute("role", "note");
      replacement.textContent = "Blocked image: " + alt;
      image.replaceWith(replacement);
    });

    root.querySelectorAll("a").forEach(function (link) {
      var href = link.getAttribute("href");
      if (!hasAllowedScheme(href)) {
        link.removeAttribute("href");
        link.setAttribute("data-blocked-link", "true");
        link.setAttribute("aria-disabled", "true");
        link.setAttribute("title", "Blocked unsafe link");
      }
    });

    root.querySelectorAll("script, iframe, object, embed").forEach(function (node) {
      node.replaceWith(document.createTextNode(node.textContent || ""));
    });
  }

  function applyTaskListCheckboxes(root) {
    root.querySelectorAll("li").forEach(function (item) {
      var textNode = null;

      for (var node = item.firstChild; node; node = node.nextSibling) {
        if (node.nodeType === 3 && /^\[[ xX]\]\s+/.test(node.nodeValue)) {
          textNode = node;
          break;
        }

        if (node.nodeType === 1) {
          break;
        }
      }

      if (!textNode) {
        return;
      }

      var checked = /^\[[xX]\]/.test(textNode.nodeValue);
      textNode.nodeValue = textNode.nodeValue.replace(/^\[[ xX]\]\s+/, "");

      var checkbox = document.createElement("input");
      checkbox.type = "checkbox";
      checkbox.disabled = true;
      checkbox.setAttribute("disabled", "");
      checkbox.checked = checked;
      if (checked) {
        checkbox.setAttribute("checked", "");
      }
      checkbox.setAttribute("aria-label", checked ? "Completed task" : "Open task");

      item.classList.add("task-list-item");
      item.insertBefore(checkbox, textNode);
    });
  }

  function applyHeadingMetadata(root, headings) {
    var queue = Array.isArray(headings) ? headings.slice() : [];

    root.querySelectorAll("h1, h2, h3, h4, h5, h6").forEach(function (heading, index) {
      var mapped = queue[index] || {};
      var level = mapped.level || Number(heading.tagName.slice(1));

      if (mapped.slug) {
        heading.id = mapped.slug;
      }

      heading.dataset.level = String(level);
    });
  }

  function colorFragmentFromText(text) {
    var pattern = /<span style="color:\s*(red|blue)">([\s\S]*?)<\/span>/gi;
    var match = null;
    var lastIndex = 0;
    var fragment = document.createDocumentFragment();
    var didReplace = false;

    while ((match = pattern.exec(text)) !== null) {
      if (match.index > lastIndex) {
        fragment.appendChild(document.createTextNode(text.slice(lastIndex, match.index)));
      }

      var color = match[1].toLowerCase();
      var span = document.createElement("span");
      span.setAttribute("data-mdsquare-color", color);
      span.style.color = color;
      span.textContent = match[2];
      fragment.appendChild(span);

      lastIndex = pattern.lastIndex;
      didReplace = true;
    }

    if (!didReplace) {
      return null;
    }

    if (lastIndex < text.length) {
      fragment.appendChild(document.createTextNode(text.slice(lastIndex)));
    }

    return fragment;
  }

  function replaceColorMarkupInTextNode(textNode) {
    var fragment = colorFragmentFromText(textNode.nodeValue || "");
    if (fragment) {
      textNode.replaceWith(fragment);
    }
  }

  function replaceColorMarkupInElement(element) {
    var fragment = colorFragmentFromText(element.textContent || "");
    if (!fragment) {
      return false;
    }

    while (element.firstChild) {
      element.removeChild(element.firstChild);
    }

    element.appendChild(fragment);
    return true;
  }

  function hasOnlyTextChildren(node) {
    if (!node.childNodes || node.childNodes.length === 0) {
      return false;
    }

    for (var index = 0; index < node.childNodes.length; index += 1) {
      if (node.childNodes[index].nodeType !== 3) {
        return false;
      }
    }

    return true;
  }

  function applyColorSpans(root) {
    if ((root.textContent || "").indexOf('<span style="color:') < 0) {
      return;
    }

    var textNodes = [];

    function collect(node) {
      if (node.nodeType === 1 && hasOnlyTextChildren(node) && replaceColorMarkupInElement(node)) {
        return;
      }

      if (node.nodeType === 3) {
        textNodes.push(node);
        return;
      }

      for (var index = 0; index < node.childNodes.length; index += 1) {
        collect(node.childNodes[index]);
      }
    }

    collect(root);
    textNodes.forEach(replaceColorMarkupInTextNode);
  }

  function render(markdown, headings, localImages) {
    var imageMap = localImages && typeof localImages === "object" ? localImages : {};
    var main = document.createElement("main");
    main.className = "preview-content";
    main.innerHTML = md.render(String(markdown || ""), { localImages: imageMap });

    sanitizeRenderedDOM(main);
    applyColorSpans(main);
    applyTaskListCheckboxes(main);
    applyHeadingMetadata(main, headings);

    var existing = document.querySelector("main.preview-content");
    if (existing) {
      existing.replaceWith(main);
    } else {
      document.body.appendChild(main);
    }

    return main.innerHTML;
  }

  function scrollToHeading(slug) {
    if (!slug) {
      return false;
    }

    var heading = document.getElementById(slug);
    if (!heading) {
      return false;
    }

    heading.scrollIntoView({ block: "start", behavior: "smooth" });
    return true;
  }

  window.MarkdownDevPreview = {
    render: render,
    scrollToHeading: scrollToHeading
  };
}());
