# Restful.js V Port

A pure V client for interacting with server-side RESTful resources. Think Restangular without Angular.

This is a V language port of the original [restful.js](https://github.com/marmelab/restful.js) library.

## Installation

```bash
v install
```

## Usage

### Create a resource targeting your API

Restful.js needs an HTTP backend in order to perform queries. Two http backend are currently available:
* `HttpBackend`: For using restful.js with V's built-in HTTP client.
* `FetchBackend`: For using restful.js in a browser with fetch.
* `RequestBackend`: For using restful.js in Node.js with request.

Start by defining the base endpoint for an API, for instance `http://api.example.com` with the good http backend.

For a V build with HTTP backend:
```v
import restful

mut api := restful.restful('http://api.example.com', &restful.HttpBackend{})
```

For a browser build with fetch:
```v
import restful

// You would need to provide a fetch implementation
fn my_fetch(url string, options restful.FetchOptions) !restful.FetchResponse {
    // Your fetch implementation
}

backend := restful.fetch_backend(my_fetch)
mut api := restful.restful('http://api.example.com', backend)
```

For a Node.js build with request:
```v
import restful

// You would need to provide a request implementation
fn my_request(options restful.RequestOptions) !restful.RequestResponse {
    // Your request implementation
}

backend := restful.request_backend(my_request)
mut api := restful.restful('http://api.example.com', backend)
```

### Collections and Members endpoints

A *collection* is an API endpoint for a list of entities, for instance `http://api.example.com/articles`. Create it using the `all(name)` syntax:

```v
mut articlesCollection := api.all('articles')  // http://api.example.com/articles
```

`articlesCollection` is just the description of the collection, the API wasn't fetched yet.

A *member* is an API endpoint for a single entity, for instance `http://api.example.com/articles/1`. Create it using the `one(name, id)` syntax:

```v
mut articleMember := api.one('articles', '1')  // http://api.example.com/articles/1
```

Just like above, `articleMember` is a description, not an entity.

You can chain `one()` and `all()` to target the required collection or member:

```v
mut articleMember := api.one('articles', '1')  // http://api.example.com/articles/1
mut commentsCollection := articleMember.all('comments')  // http://api.example.com/articles/1/comments
```

#### Custom endpoint URL

In case you need to set a custom endpoint URL, you can use `custom` methods.

```v
mut articleCustom := api.custom('articles/beta', true)  // http://api.example.com/articles/beta

// you can add an absolute url
mut articleCustom := api.custom('http://custom.url/articles/beta', false)  // http://custom.url/articles/beta
```

A custom endpoint acts like a member, and therefore you can use `one` and `all` to chain other endpoint with it.

#### Entities

Once you have collections and members endpoints, fetch them to get *entities*. Restful.js exposes `get()` and `getAll()` methods for fetching endpoints. Since these methods are asynchronous, they return a result or error.

```v
mut articleMember := api.one('articles', '1')  // http://api.example.com/articles/1
articleEntity := articleMember.get(map[string]string{}, map[string]string{})!

article := articleEntity.data()
println(article['title']) // hello, world!

mut commentsCollection := articleMember.all('comments')  // http://api.example.com/articles/1/comments
commentEntities := commentsCollection.getAll(map[string]string{}, map[string]string{})!

for commentEntity in commentEntities {
    comment := commentEntity.data()
    println(comment['body'])
}
```

*Tip*: You can describe a member based on a collection *and* trigger the API fetch at the same time by calling `get(id)`:

```v
// fetch http://api.example.com/articles/1/comments/4
mut articleMember := api.one('articles', '1')
mut commentMember := articleMember.one('comments', '4')
commentEntity := commentMember.get(map[string]string{}, map[string]string{})!

// equivalent to
mut commentsCollection := articleMember.all('comments')
commentEntity := commentsCollection.get('4', map[string]string{}, map[string]string{})!
```

### Response

A response is made from the HTTP response fetched from the endpoint. It exposes `status_code()`, `headers()`, and `body()` methods. For a `GET` request, the `body` method will return one or an array of entities. Therefore you can disable this hydration by calling `body(false)`.

### Entity Data

An entity is made from the HTTP response data fetched from the endpoint. It exposes a `data()` method:

```v
mut articleCollection := api.all('articles')  // http://api.example.com/articles

// http://api.example.com/articles/1
mut articleMember := api.one('articles', '1')
articleEntity := articleMember.get(map[string]string{}, map[string]string{})!

// if the server response was { id: 1, title: 'test', body: 'hello' }
article := articleEntity.data()
article['title'] // returns `test`
article['body'] // returns `hello`
// You can also edit it
article['title'] = json.Any('test2')
// Finally you can easily update it or delete it
articleEntity.save()! // will perform a PUT request
articleEntity.delete()! // will perform a DELETE request
```

You can also use the entity to continue exploring the API. Entities expose several other methods to chain calls:

* `entity.one ( name, id )`: Query a member child of the entity.
* `entity.all ( name )`: Query a collection child of the entity.
* `entity.url ()`: Get the entity url.
* `entity.save ( [, data [, params [, headers ]]] )`: Save the entity modifications by performing a POST request.
* `entity.delete ( [, data [, params [, headers ]]] )`: Remove the entity by performing a DELETE request.
* `entity.id ()`: Get the id of the entity.

```v
mut articleMember := api.one('articles', '1')  // http://api.example.com/articles/1
mut commentMember := articleMember.one('comments', '3')  // http://api.example.com/articles/1/comments/3
commentEntity := commentMember.get(map[string]string{}, map[string]string{})!

// You can also call `all` and `one` on an entity
authorEntities := commentEntity.all('authors').getAll(map[string]string{}, map[string]string{})!

for authorEntity in authorEntities {
    author := authorEntity.data()
    println(author['name'])
}
```

`entity.id()` will get the id from its data regarding of the `identifier` of its endpoint. If you are using another name than `id` you can modify it by calling `identifier()` on the endpoint.

```v
mut articleCollection := api.all('articles')  // http://api.example.com/articles
articleCollection.identifier('_id') // We use _id as id field

mut articleMember := api.one('articles', '1')  // http://api.example.com/articles/1
articleMember.identifier('_id') // We use _id as id field
```

Restful.js uses an inheritance pattern when collections or members are chained. That means that when you configure a collection or a member, it will configure all the collection on members chained afterwards.

```v
// configure the api
api.header('AuthToken', 'test')
api.identifier('_id')

mut articlesCollection := api.all('articles')
articlesCollection.get('1', map[string]string{}, map[string]string{})! // will send the `AuthToken` header
// You can configure articlesCollection, too
articlesCollection.header('foo', 'bar')
articlesCollection.one('comments', '1').get(map[string]string{}, map[string]string{})! // will send both the AuthToken and foo headers
```

## API Reference

Restful.js exposes similar methods on collections, members and entities. The name are consistent, and the arguments depend on the context.

### Collection methods

* `addErrorInterceptor ( interceptor )`: Add an error interceptor. You can alter the whole error.
* `addRequestInterceptor ( interceptor )`: Add a request interceptor. You can alter the whole request.
* `addResponseInterceptor ( interceptor )`: Add a response interceptor. You can alter the whole response.
* `custom ( name [, isRelative = true ] )`: Target a child member with a custom url.
* `delete ( id [, data [, params [, headers ]]] )`: Delete a member in a collection. Returns a promise with the response.
* `getAll ( [ params [, headers ]] )`: Get a full collection. Returns a promise with an array of entities.
* `get ( id [, params [, headers ]] )`: Get a member in a collection. Returns a promise with an entity.
* `head ( id [, params [, headers ]] )`: Perform a HEAD request on a member in a collection. Returns a promise with the response.
* `header ( name, value )`: Add a header.
* `headers ()`: Get all headers added to the collection.
* `on ( event, listener )`: Add an event listener on the collection.
* `once ( event, listener )`: Add an event listener on the collection which will be triggered only once.
* `patch ( id [, data [, params [, headers ]]] )`: Patch a member in a collection. Returns a promise with the response.
* `post ( [ data [, params [, headers ]]] )`: Create a member in a collection. Returns a promise with the response.
* `put ( id [, data [, params [, headers ]]] )`: Update a member in a collection. Returns a promise with the response.
* `url ()`: Get the collection url.

### Member methods

* `addErrorInterceptor ( interceptor )`: Add an error interceptor. You can alter the whole error.
* `addRequestInterceptor ( interceptor )`: Add a request interceptor. You can alter the whole request.
* `addResponseInterceptor ( interceptor )`: Add a response interceptor. You can alter the whole response.
* `all ( name )`: Target a child collection `name`.
* `custom ( name [, isRelative = true ] )`: Target a child member with a custom url.
* `delete ( [ data [, params [, headers ]]] )`: Delete a member. Returns a promise with the response.
* `get ( [ params [, headers ]] )`: Get a member. Returns a promise with an entity.
* `head ( [ params [, headers ]] )`: Perform a HEAD request on a member. Returns a promise with the response.
* `header ( name, value )`: Add a header.
* `headers ()`: Get all headers added to the member.
* `on ( event, listener )`: Add an event listener on the member.
* `once ( event, listener )`: Add an event listener on the member which will be triggered only once.
* `one ( name, id )`: Target a child member in a collection `name`.
* `patch ( [ data [, params [, headers ]]] )`: Patch a member. Returns a promise with the response.
* `post ( [ data [, params [, headers ]]] )`: Create a member. Returns a promise with the response.
* `put ( [ data [, params [, headers ]]] )`: Update a member. Returns a promise with the response.
* `url ()`: Get the member url.

### Interceptors

An error, response or request interceptor is a callback which looks like this:

```v
resource.add_request_interceptor(fn (config restful.RequestConfig) restful.RequestConfig {
    data := config.data
    headers := config.headers
    method := config.method
    params := config.params
    url := config.url
    // all args had been modified
    return {
        data: data,
        params: params,
        headers: headers,
        method: method,
        url: url,
    }

    // just return modified arguments
    return {
        data: data,
        headers: headers,
    }
})

resource.add_response_interceptor(fn (response restful.Response, config restful.RequestConfig) restful.Response {
    data := response.body
    headers := response.headers
    status_code := response.status_code
    // all args had been modified
    return {
        body: data,
        headers: headers,
        status_code: status_code
    }

    // just return modified arguments
    return {
        body: data,
        headers: headers,
    }
})

resource.add_error_interceptor(fn (err IError, config restful.RequestConfig) IError {
    message := err.msg()
    // all args had been modified
    return error(message)

    // just return modified arguments
    return error(message)
})
```

### Response methods

* `body ()`: Get the HTTP body of the response. If it is a `GET` request, it will hydrate some entities. To get the raw body call it with `false` as argument.
* `headers ()`: Get the HTTP headers of the response.
* `status_code ()`: Get the HTTP status code of the response.

### Entity methods

* `all ( name )`: Query a collection child of the entity.
* `custom ( name [, isRelative = true ] )`: Target a child member with a custom url.
* `data ()` : Get the V map unserialized from the response body (which must be in JSON)
* `id ()`: Get the id of the entity.
* `one ( name, id )`: Query a member child of the entity.
* `delete ( [, data [, params [, headers ]]] )`: Delete the member link to the entity. Returns a promise with the response.
* `save ( [, data [, params [, headers ]]] )`: Update the member link to the entity. Returns a promise with the response.
* `url ()`: Get the entity url.

### Error Handling

To deal with errors, you can either use error interceptors, error callbacks on promise or error events.

```v
mut commentMember := api.one('articles', '1').one('comments', '2')
commentEntity := commentMember.get(map[string]string{}, map[string]string{}) or {
    // deal with the error
    return
}

commentMember.on('error', fn (error IError, config restful.RequestConfig) {
    // deal with the error
})
```

### Events

Any endpoint (collection or member) is an event emitter. It emits `request`, `response` and `error` events. When it emits an event, it is propagated to all its parents. This way you can listen to all errors, requests and response on your restful instance by listening on your root endpoint.

```v
api.on('error', fn (data restful.EventData) {
    // deal with the error
})

api.on('request', fn (data restful.EventData) {
    // deal with the request
})

api.on('response', fn (data restful.EventData) {
    // deal with the response
})
```

When you use interceptors, endpoints will also emit `request:interceptor:pre`, `request:interceptor:post`, `response:interceptor:pre`, `response:interceptor:post`, `error:interceptor:pre` and `error:interceptor:post`:

```v
api.on('error:interceptor:pre', fn (data restful.EventData) {
    // deal with the error
})

api.on('error:interceptor:post', fn (data restful.EventData) {
    // deal with the error
})

api.on('request:interceptor:pre', fn (data restful.EventData) {
    // deal with the request
})

api.on('request:interceptor:post', fn (data restful.EventData) {
    // deal with the request
})

api.on('response:interceptor:pre', fn (data restful.EventData) {
    // deal with the response
})

api.on('response:interceptor:post', fn (data restful.EventData) {
    // deal with the response
})
```

You can also use `once` method to add a one shot event listener.

## Development

Install dependencies:

```bash
v install
```

### Run tests

```bash
v test ./tests
```

### Run examples

```bash
v run examples/basic.v
v run examples/advanced.v
v run examples/nodejs.v
```

## Contributing

All contributions are welcome. If you add a new feature, please write tests for it.

## License

This application is available under the [MIT License](https://github.com/marmelab/restful.js/blob/master/LICENSE), courtesy of [marmelab](http://marmelab.com).