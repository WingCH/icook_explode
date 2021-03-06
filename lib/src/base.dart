import 'dart:convert';

import 'package:http/http.dart' as http;

import '/icook_explode.dart';

class IcookExplode {
  Future<RecipesModel> search({
    http.Client? httpClient,

    /// 食譜名
    required String recipeName,
    int? page,
  }) async {
    httpClient = httpClient ?? http.Client();
    var url = Uri.https(
      'icook.tw',
      '/search/$recipeName',
      page == null ? null : {"page": page.toString()},
    );
    http.Response response = await httpClient.get(url);

    if (response.statusCode == 200) {
      return IcookExplodeParser()
          .searchContentParser(const Utf8Decoder().convert(response.bodyBytes));
    } else {
      throw IcookExplodeRequestErrorException(
        code: response.statusCode,
        message: response.reasonPhrase,
        response: response,
      );
    }
  }

  Future<RecipeDetailModel> getRecipe({
    http.Client? httpClient,
    required String path,
  }) async {
    httpClient = httpClient ?? http.Client();
    var url = Uri.https(
      'icook.tw',
      path,
    );
    http.Response response = await httpClient.get(url);
    final String rawHtml = const Utf8Decoder().convert(response.bodyBytes);
    if (response.statusCode == 200) {
      return IcookExplodeParser().detailContentParser(rawHtml);
    } else if (response.statusCode == 404) {
      throw IcookExplodeNotFindException(rawHtml: rawHtml);
    } else {
      throw IcookExplodeRequestErrorException(
        code: response.statusCode,
        message: response.reasonPhrase,
        response: response,
      );
    }
  }
}
