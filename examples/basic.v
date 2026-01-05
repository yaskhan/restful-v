module main

import restful
import x.json2 as json

fn main() {
	// Использование с HTTP backend
	mut api := restful.restful('http://api.example.com', &restful.HttpBackend{})

	// Работа с коллекцией
	mut articles := api.all('articles')

	// Получить все статьи
	all_articles := articles.get_all(map[string]string{}, map[string]string{})!
	for article in all_articles {
		data := article.data()
		println('Article: ${data['title'] or { json.Any('') }.str()}')
	}

	// Получить одну статью
	article := articles.get('1', map[string]string{}, map[string]string{})!
	data := article.data()
	println('Title: ${data['title'] or { json.Any('') }.str()}')

	// Создать статью
	new_article := {
		'title': json.Any('New Article')
		'body':  json.Any('Content here')
	}
	response := articles.post(new_article, map[string]string{}, map[string]string{})!
	println('Created: ${response.status_code}')

	// Обновить статью
	mut article_entity := articles.get('1', map[string]string{}, map[string]string{})!
	mut article_data := article_entity.data()
	article_data['title'] = json.Any('Updated Title')
	article_entity.save()!

	// Удалить статью
	article_entity.delete()!

	// Работа с вложенными ресурсами
	mut comments := articles.one('comments', '5')
	comment := comments.get(map[string]string{}, map[string]string{})!
	comment_data := comment.data()
	println('Comment: ${comment_data['body'] or { json.Any('') }.str()}')

	// Цепочка вызовов
	mut member := api.one('articles', '1')
	mut nested := member.one('comments', '5')
	nested.get(map[string]string{}, map[string]string{})!
}
