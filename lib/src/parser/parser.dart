import 'package:collection/src/iterable_extensions.dart';
import 'package:icook_explode/src/extension/string_ex.dart';
import 'package:universal_html/html.dart';
import 'package:universal_html/parsing.dart';

import '/icook_explode.dart';

class IcookExplodeParser {
  RecipesModel searchContentParser(String rawHtml) {
    HtmlDocument document = parseHtmlDocument(rawHtml);

    // 如果有 #search-placeholder, 等於找不到相關食譜
    if (document.getElementsByClassName("search-placeholder").isNotEmpty) {
      throw IcookExplodeNotFindException(rawHtml: rawHtml);
    }

    /// 驗證，如果無result-browse-layout, 當係invalid
    final List<Node> verifyNode =
        document.getElementsByClassName("result-browse-layout");

    if (verifyNode.isEmpty) {
      throw IcookExplodeInvalidContentException(rawHtml: rawHtml);
    }

    /// 食譜名稱
    /// e.g: 羅宋湯
    final List<Node> nameNode =
        document.getElementsByClassName("browse-title-name");
    String? name = nameNode.isEmpty
        ? null
        : nameNode.first.text?.removeNewLinesAndWhitespaces();

    /// 食譜總數 (只供參考)
    /// 234 道食譜
    final List<Node> recipesTotalCountNode =
        document.getElementsByClassName("browse-title-count");
    String? recipesTotalCount = recipesTotalCountNode.isEmpty
        ? null
        : recipesTotalCountNode.first.text?.removeNewLinesAndWhitespaces();

    /// 食譜簡介
    /// e.g: 正宗羅宋湯紫紅的色澤是來自於甜菜根！
    final List<Node> descriptionElement = document
        .getElementsByClassName("styles-module__searchKeywordContent___hdMIz");
    String? description = descriptionElement.isEmpty
        ? null
        : descriptionElement.first.nodes.isEmpty
            ? null
            : descriptionElement.first.nodes.first.text
                ?.removeNewLinesAndWhitespaces();

    /// 食譜常見料理
    /// e.g: [
    ///         "羅宋牛肉湯",
    ///         "蔬菜湯",
    ///         "牛肉湯",
    ///         "番茄湯"
    ///     ]
    /// 見到網站有兩個format, 一時一樣咁, 所以map晒兩個

    final ElementList<Element> suggestionsElement1 = document
        .querySelectorAll("ul.filters-recipes > li.filters-recipe > a > span");
    List<String>? suggestions = suggestionsElement1
        .map((Node e) => e.text?.removeNewLinesAndWhitespaces())
        .toList()
        .whereType<String>()
        .toList();

    if (suggestions.isEmpty) {
      final ElementList<Element> suggestionsElement2 = document.querySelectorAll(
          "#o-wrapper > div:nth-child(6) > div.row.row--flex > main > header > section:nth-child(5) > ul > li > a");
      suggestions = suggestionsElement2
          .map((Node e) => e.text?.removeNewLinesAndWhitespaces())
          .toList()
          .whereType<String>()
          .toList();
    }

    /// 食譜
    final List<Node>? recipesNode =
        document.getElementsByClassName("browse-recipe-item");

    final List<Recipe>? recipes = recipesNode?.map((recipeNode) {
      /// 找不到方法直接取得當前的Element, 透過子節點再用parent間接
      final Element? currentElement = recipeNode.hasChildNodes()
          ? recipeNode.childNodes.first.parent
          : null;

      /// 內頁路徑, e.g: /recipes/397794
      final String? detailPath =
          currentElement?.querySelector("a")?.getAttribute("href");

// 圖片連結, e.g: https://imageproxy.icook.network/resize?background=255%2C255%2C255&amp;height=150&amp;nocrop=false&amp;stripmeta=true&amp;type=auto&amp;url=http%3A%2F%2Ftokyo-kitchen.icook.tw.s3.amazonaws.com%2Fuploads%2Frecipe%2Fcover%2F397794%2F72545b5990736c25.jpg&amp;width=200
      final String? imgUrl = currentElement
          ?.querySelector("a > article > div.browse-recipe-cover > img")
          ?.getAttribute("data-src");

      /// e.g: 羅宋湯
      final String? name = currentElement
          ?.querySelector("a > article > div.browse-recipe-content > div > h2")
          ?.text
          ?.removeNewLinesAndWhitespaces();

      /// e.g: 牛肉羅宋湯，一鍋到底的不正宗口味，哈哈！沒買到月桂葉，但是味道也是很美味。
      final String? description = currentElement
          ?.querySelector(
              "a > article > div.browse-recipe-content > div > blockquote")
          ?.text
          ?.removeNewLinesAndWhitespaces();

      /// 成份, e.g: 食材：牛肋條、牛番茄、鹽巴、紅蘿蔔、白胡椒粉、洋蔥、黑胡椒、義大利香料粉、番茄醬
      final String? ingredient = currentElement
          ?.querySelector("a > article > div.browse-recipe-content > div > p")
          ?.text
          ?.removeNewLinesAndWhitespaces();

      /// 烹飪時間, e.g: 45 分
      String? cookingTime = currentElement
          ?.querySelector(
              "a > article > div.browse-recipe-content > ul.browse-recipe-meta > li.browse-recipe-meta-item:nth-child(1)")
          ?.text
          ?.removeNewLinesAndWhitespaces();

      /// 處理沒有"烹飪時間"的情況
      if (cookingTime != null) {
        cookingTime = cookingTime.contains("分") ? cookingTime : null;
      }

      return Recipe(
        detailUrl: detailPath,
        image: imgUrl,
        name: name,
        description: description,
        ingredient: ingredient,
        cookingTime: cookingTime,
      );
    }).toList();

    return RecipesModel(
      name: name,
      description: description,
      recipesTotalCount: recipesTotalCount,
      suggestions: suggestions,
      recipes: recipes,
    );
  }

  RecipeDetailModel detailContentParser(String rawHtml) {
    HtmlDocument document = parseHtmlDocument(rawHtml);

    /// 驗證，如果無recipe-details-header-title, 當係invalid
    final List<Node> verifyNode =
        document.getElementsByClassName("recipe-details-header-title");

    if (verifyNode.isEmpty) {
      throw IcookExplodeInvalidContentException(rawHtml: rawHtml);
    }

    /// 食譜名稱
    /// e.g: 羅宋湯
    String? name = document
        .getElementById("recipe-name")
        ?.text
        ?.removeNewLinesAndWhitespaces();

    /// 食譜簡介
    /// e.g: 牛肉羅宋湯，一鍋到底的不正宗口味，哈哈！沒買到月桂葉，但是味道也是很美味。
    final String? description = document
        .querySelector(
            "div.recipe-details > div.recipe-details-header.recipe-details-block > section > p")
        ?.text
        ?.removeNewLinesAndWhitespaces();

    /// 份量
    /// e.g: 3人份
    final String? servings = document
        .querySelector(
            "div.recipe-details-info.recipe-details-block > div.servings-info.info-block > div.info-content > div.servings")
        ?.text
        ?.removeNewLinesAndWhitespaces();

    /// 時間
    /// e.g: 45分鐘
    final String? time = document
        .querySelector(
            "div.recipe-details-info.recipe-details-block > div.time-info.info-block > div.info-content")
        ?.text
        ?.removeNewLinesAndWhitespaces();

    /// 食材, https://icook.tw/recipes/397794
    List<Element> ingredientsGroupsElement = document
        .querySelectorAll(
            "div.recipe-details > div.recipe-details-ingredients.recipe-details-block > div > div")
        .toList();

    List<IngredientsGroup> ingredientsGroup =
        ingredientsGroupsElement.map((ingredientsGroupElement) {
      /// 食材類別名稱
      /// e.g: 調味
      final List<Node> categoryNode =
          ingredientsGroupElement.getElementsByClassName("group-name");
      String? categoryName = categoryNode.isEmpty
          ? null
          : categoryNode.first.text?.removeNewLinesAndWhitespaces();

      /// 食材類別列表
      final ElementList<Element> ingredientsElement = ingredientsGroupElement
          .querySelectorAll("div.ingredients > div.ingredient");

      /// 食材列表
      List<Ingredient> ingredients =
          ingredientsElement.map((ingredientElement) {
        final Element? ingredientNameElement =
            ingredientElement.querySelector("div.ingredient-name > a");

        /// 食材名
        /// e.g: 牛肋條
        String? ingredientName =
            ingredientNameElement?.text?.removeNewLinesAndWhitespaces();

        /// 食材search path
        /// e.g: /search/%E9%A3%9F%E6%9D%90%EF%BC%9A%E7%89%9B%E8%82%8B%E6%A2%9D/
        String? ingredientHrefPath =
            ingredientNameElement?.getAttribute("href");

        /// 食材用量
        /// e.g: 一盒
        String? ingredientUnit = ingredientElement
            .querySelector("div.ingredient-unit")
            ?.text
            ?.removeNewLinesAndWhitespaces();

        return Ingredient(
          name: ingredientName,
          href: ingredientHrefPath,
          unit: ingredientUnit,
        );
      }).toList();

      return IngredientsGroup(
        category: categoryName,
        ingredients: ingredients,
      );
    }).toList();

    /// 步驟
    final ElementList<Element> processStepsNode = document.querySelectorAll(
        "div.recipe-details > div.recipe-details-howto > ul.recipe-details-steps > li.recipe-details-step-item");

    final List<ProcessStep> processSteps =
        processStepsNode.mapIndexed((index, processStep) {
      final imgUrl =
          processStep.querySelector("figure > a")?.getAttribute("href");
      final description = processStep
          .querySelector(
              "figure > figcaption > p.recipe-step-description-content")
          ?.text;

      return ProcessStep(
        index: index,
        imageUrl: imgUrl,
        description: description,
      );
    }).toList();

    return RecipeDetailModel(
      name: name,
      description: description,
      servings: servings,
      time: time,
      ingredientsGroups: ingredientsGroup,
      processSteps: processSteps,
    );
  }
}
