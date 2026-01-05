module tests

import restful
import x.json2 as json

// Mock backend for entity tests
struct EntityMockBackend {
mut:
	response restful.Response
	error    IError
}

pub fn (b EntityMockBackend) do(req restful.RequestConfig) !restful.Response {
    if b.error != IError(none) {
        return b.error
    }
    return b.response
}

fn test_entity_data() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"id": "1", "title": "Test", "body": "Content"}'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
	mut member := api.one('articles', '1')

	entity := member.get(map[string]string{}, map[string]string{})!
	data := entity.data()

	assert data['id'] == json.Any('1')
	assert data['title'] == json.Any('Test')
	assert data['body'] == json.Any('Content')
}

fn test_entity_id() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"id": "123", "title": "Test"}'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut entity := member.get(map[string]string{}, map[string]string{})!
    assert entity.id() == '123'
}

fn test_entity_url() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"id": "1", "title": "Test"}'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut entity := member.get(map[string]string{}, map[string]string{})!
    assert entity.url() == 'http://api.example.com/articles/1'
}

fn test_entity_save() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"id": "1", "title": "Updated"}'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut entity := member.get(map[string]string{}, map[string]string{})!
    mut entity_data := entity.data()
    entity_data['title'] = json.Any('Updated')

    response := entity.save()!
    assert response.status_code == 200
}

fn test_entity_delete() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 204
            headers:     map[string]string{}
            body:        ''
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut entity := member.get(map[string]string{}, map[string]string{})!
    response := entity.delete()!
    assert response.status_code == 204
}

fn test_entity_one() {
    backend := EntityMockBackend{}
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut entity := member.get(map[string]string{}, map[string]string{})!
    mut nested_member := entity.one('comments', '5')

    assert nested_member.url() == 'http://api.example.com/articles/1/comments/5'
}

fn test_entity_all() {
    backend := EntityMockBackend{}
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut entity := member.get(map[string]string{}, map[string]string{})!
    mut collection := entity.all('comments')

    assert collection.url() == 'http://api.example.com/articles/1/comments'
}

fn test_entity_custom() {
    backend := EntityMockBackend{}
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut entity := member.get(map[string]string{}, map[string]string{})!
    mut custom := entity.custom('special', true)

    assert custom.url() == 'http://api.example.com/articles/1/special'
}

fn test_collection_get() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"id": "1", "title": "Test"}'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')

    mut entity := collection.get('1', map[string]string{}, map[string]string{})!
    data := entity.data()

    assert data['id'] == json.Any('1')
    assert data['title'] == json.Any('Test')
}

fn test_collection_get_all() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '[{"id": "1", "title": "Test 1"}, {"id": "2", "title": "Test 2"}]'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')

    entities := collection.get_all(map[string]string{}, map[string]string{})!
    assert entities.len == 2

    first := entities[0].data()
    second := entities[1].data()

    assert first['id'] == json.Any('1')
    assert first['title'] == json.Any('Test 1')
    assert second['id'] == json.Any('2')
    assert second['title'] == json.Any('Test 2')
}

fn test_collection_post() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 201
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"id": "1", "title": "New"}'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')

    data := {
        'title': json.Any('New')
    }

    response := collection.post(data, map[string]string{}, map[string]string{})!
    assert response.status_code == 201
}

fn test_collection_put() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"id": "1", "title": "Updated"}'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')

    data := {
        'title': json.Any('Updated')
    }

    response := collection.put('1', data, map[string]string{}, map[string]string{})!
    assert response.status_code == 200
}

fn test_collection_patch() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"id": "1", "title": "Patched"}'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')

    data := {
        'title': json.Any('Patched')
    }

    response := collection.patch('1', data, map[string]string{}, map[string]string{})!
    assert response.status_code == 200
}

fn test_collection_delete() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 204
            headers:     map[string]string{}
            body:        ''
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')

    response := collection.delete('1', map[string]json.Any{}, map[string]string{}, map[string]string{})!
    assert response.status_code == 204
}

fn test_collection_head() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     map[string]string{}
            body:        ''
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')

    response := collection.head('1', map[string]string{}, map[string]string{})!
    assert response.status_code == 200
}

fn test_collection_one() {
    backend := EntityMockBackend{}
    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')

    mut member := collection.one('comments', '5')
    assert member.url() == 'http://api.example.com/articles/5/comments'
}

fn test_collection_custom() {
    backend := EntityMockBackend{}
    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')

    mut custom := collection.custom('special', true)
    assert custom.url() == 'http://api.example.com/articles/special'
}

fn test_member_get() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"id": "1", "title": "Test"}'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut entity := member.get(map[string]string{}, map[string]string{})!
    data := entity.data()

    assert data['id'] == json.Any('1')
    assert data['title'] == json.Any('Test')
}

fn test_member_post() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 201
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"id": "1", "title": "New"}'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    data := {
        'title': json.Any('New')
    }

    response := member.post(data, map[string]string{}, map[string]string{})!
    assert response.status_code == 201
}

fn test_member_put() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"id": "1", "title": "Updated"}'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    data := {
        'title': json.Any('Updated')
    }

    response := member.put(data, map[string]string{}, map[string]string{})!
    assert response.status_code == 200
}

fn test_member_patch() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"id": "1", "title": "Patched"}'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    data := {
        'title': json.Any('Patched')
    }

    response := member.patch(data, map[string]string{}, map[string]string{})!
    assert response.status_code == 200
}

fn test_member_delete() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 204
            headers:     map[string]string{}
            body:        ''
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    response := member.delete(none, map[string]string{}, map[string]string{})!
    assert response.status_code == 204
}

fn test_member_head() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     map[string]string{}
            body:        ''
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    response := member.head(map[string]string{}, map[string]string{})!
    assert response.status_code == 200
}

fn test_member_one() {
    backend := EntityMockBackend{}
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut nested_member := member.one('comments', '5')
    assert nested_member.url() == 'http://api.example.com/articles/1/comments/5'
}

fn test_member_all() {
    backend := EntityMockBackend{}
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut collection := member.all('comments')
    assert collection.url() == 'http://api.example.com/articles/1/comments'
}

fn test_member_custom() {
    backend := EntityMockBackend{}
    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut custom := member.custom('special', true)
    assert custom.url() == 'http://api.example.com/articles/1/special'
}

fn test_entity_chaining() {
    backend := EntityMockBackend{}
    mut api := restful.restful('http://api.example.com', backend)

    mut article := api.one('articles', '1')
    mut comments := article.all('comments')
    mut authors := comments.one('authors', '2')

    assert authors.url() == 'http://api.example.com/articles/1/comments/2/authors'
}

fn test_collection_chaining() {
    backend := EntityMockBackend{}
    mut api := restful.restful('http://api.example.com', backend)

    mut articles := api.all('articles')
    mut article := articles.one('comments', '5')
    mut authors := article.all('authors')

    assert authors.url() == 'http://api.example.com/articles/5/comments/authors'
}

fn test_entity_custom_identifier() {
	mut backend := EntityMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"_id": "abc123", "title": "Test"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	api.identifier('_id')

	mut member := api.one('articles', '1')
	member.identifier('_id')

	entity := member.get(map[string]string{}, map[string]string{})!
	assert entity.id() == 'abc123'
}

fn test_collection_custom_identifier() {
	mut backend := EntityMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[{"_id": "abc", "title": "Test 1"}, {"_id": "def", "title": "Test 2"}]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	api.identifier('_id')

	mut collection := api.all('articles')
	collection.identifier('_id')

	entities := collection.get_all(map[string]string{}, map[string]string{})!
	assert entities.len == 2

	first := entities[0]
	second := entities[1]

	assert first.id() == 'abc'
	assert second.id() == 'def'
}

fn test_entity_data_modification() {
	mut backend := EntityMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1", "title": "Original", "count": 0}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut member := api.one('articles', '1')

	entity := member.get(map[string]string{}, map[string]string{})!
	mut data := entity.data()

	// Modify data
	data['title'] = json.Any('Modified')
	data['count'] = json.Any(5)

	assert data['title'] == json.Any('Modified')
	assert data['count'] == json.Any(5)
}

fn test_entity_url_with_custom_identifier() {
	mut backend := EntityMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"_id": "xyz789", "title": "Test"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	api.identifier('_id')

	mut member := api.one('articles', '1')
	member.identifier('_id')

	entity := member.get(map[string]string{}, map[string]string{})!
	assert entity.url() == 'http://api.example.com/articles/1'
}

fn test_collection_get_with_params() {
	mut backend := EntityMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1", "title": "Test"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut collection := api.all('articles')

	params := {
		'include': 'author'
	}
	headers := {
		'X-Custom': 'value'
	}

	entity := collection.get('1', params, headers)!
	data := entity.data()

	assert data['id'] == json.Any('1')
}

fn test_collection_get_all_with_params() {
	mut backend := EntityMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '[{"id": "1", "title": "Test 1"}]'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut collection := api.all('articles')

	params := {
		'limit':  '10'
		'offset': '0'
	}
	headers := {
		'X-Custom': 'value'
	}

	entities := collection.get_all(params, headers)!
	assert entities.len == 1
}

fn test_member_get_with_params() {
	mut backend := EntityMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1", "title": "Test"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut member := api.one('articles', '1')

	params := {
		'include': 'comments'
	}
	headers := {
		'X-Custom': 'value'
	}

	entity := member.get(params, headers)!
	data := entity.data()

	assert data['id'] == json.Any('1')
}

fn test_entity_save_with_params() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"id": "1", "title": "Saved"}'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut entity := member.get(map[string]string{}, map[string]string{})!
    mut entity_data := entity.data()
    entity_data['title'] = json.Any('Saved')

    response := entity.save()!
    assert response.status_code == 200
}

fn test_entity_delete_with_params() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 204
            headers:     map[string]string{}
            body:        ''
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut entity := member.get(map[string]string{}, map[string]string{})!
    response := entity.delete()!
    assert response.status_code == 204
}

fn test_collection_post_with_params() {
	mut backend := EntityMockBackend{
		response: restful.Response{
			status_code: 201
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1", "title": "New"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut collection := api.all('articles')

	data := {
		'title': json.Any('New')
	}
	params := {
		'validate': 'true'
	}
	headers := {
		'X-Request-ID': '123'
	}

	response := collection.post(data, params, headers)!
	assert response.status_code == 201
}

fn test_member_post_with_params() {
	mut backend := EntityMockBackend{
		response: restful.Response{
			status_code: 201
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1", "title": "New"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut member := api.one('articles', '1')

	data := {
		'title': json.Any('New')
	}
	params := {
		'validate': 'true'
	}
	headers := {
		'X-Request-ID': '123'
	}

	response := member.post(data, params, headers)!
	assert response.status_code == 201
}

fn test_member_put_with_params() {
	mut backend := EntityMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1", "title": "Updated"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut member := api.one('articles', '1')

	data := {
		'title': json.Any('Updated')
	}
	params := {
		'force': 'true'
	}
	headers := {
		'X-Update-Type': 'full'
	}

	response := member.put(data, params, headers)!
	assert response.status_code == 200
}

fn test_member_patch_with_params() {
	mut backend := EntityMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1", "title": "Patched"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut member := api.one('articles', '1')

	data := {
		'title': json.Any('Patched')
	}
	params := {
		'partial': 'true'
	}
	headers := {
		'X-Patch-Type': 'partial'
	}

	response := member.patch(data, params, headers)!
	assert response.status_code == 200
}

fn test_member_delete_with_data() {
	mut backend := EntityMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"deleted": true}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut member := api.one('articles', '1')

	data := {
		'reason': json.Any('test')
	}

	response := member.delete(data, map[string]string{}, map[string]string{})!
	assert response.status_code == 200
}

fn test_collection_put_with_params() {
	mut backend := EntityMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1", "title": "Updated"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut collection := api.all('articles')

	data := {
		'title': json.Any('Updated')
	}
	params := {
		'force': 'true'
	}
	headers := {
		'X-Update-Type': 'full'
	}

	response := collection.put('1', data, params, headers)!
	assert response.status_code == 200
}

fn test_collection_patch_with_params() {
	mut backend := EntityMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"id": "1", "title": "Patched"}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut collection := api.all('articles')

	data := {
		'title': json.Any('Patched')
	}
	params := {
		'partial': 'true'
	}
	headers := {
		'X-Patch-Type': 'partial'
	}

	response := collection.patch('1', data, params, headers)!
	assert response.status_code == 200
}

fn test_collection_delete_with_data() {
	mut backend := EntityMockBackend{
		response: restful.Response{
			status_code: 200
			headers:     {
				'Content-Type': 'application/json'
			}
			body:        '{"deleted": true}'
		}
	}

	mut api := restful.restful('http://api.example.com', backend)
	mut collection := api.all('articles')

	data := {
		'reason': json.Any('test')
	}

	response := collection.delete('1', data, map[string]string{}, map[string]string{})!
	assert response.status_code == 200
}

fn test_entity_save_with_data() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"id": "1", "title": "Saved", "count": 5}'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut entity := member.get(map[string]string{}, map[string]string{})!
    mut entity_data := entity.data()
    entity_data['title'] = json.Any('Saved')
    entity_data['count'] = json.Any(5)

    response := entity.save()!
    assert response.status_code == 200
}

fn test_entity_delete_with_data() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"deleted": true}'
        }
        error: IError(none)
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut entity := member.get(map[string]string{}, map[string]string{})!

    response := entity.delete()!
    assert response.status_code == 200
}

fn test_entity_one_with_params() {
	backend := EntityMockBackend{}
	mut api := restful.restful('http://api.example.com', backend)
	mut member := api.one('articles', '1')

	entity := member.get(map[string]string{}, map[string]string{})!
	mut nested_member := entity.one('comments', '5')

	assert nested_member.url() == 'http://api.example.com/articles/1/comments/5'
}

fn test_entity_all_with_params() {
	backend := EntityMockBackend{}
	mut api := restful.restful('http://api.example.com', backend)
	mut member := api.one('articles', '1')

	entity := member.get(map[string]string{}, map[string]string{})!
	mut collection := entity.all('comments')

	assert collection.url() == 'http://api.example.com/articles/1/comments'
}

fn test_entity_custom_with_params() {
	backend := EntityMockBackend{}
	mut api := restful.restful('http://api.example.com', backend)
	mut member := api.one('articles', '1')

	entity := member.get(map[string]string{}, map[string]string{})!
	mut custom := entity.custom('special', true)

	assert custom.url() == 'http://api.example.com/articles/1/special'
}

fn test_collection_one_with_params() {
	backend := EntityMockBackend{}
	mut api := restful.restful('http://api.example.com', backend)
	mut collection := api.all('articles')

	mut member := collection.one('comments', '5')
	assert member.url() == 'http://api.example.com/articles/5/comments'
}

fn test_collection_custom_with_params() {
	backend := EntityMockBackend{}
	mut api := restful.restful('http://api.example.com', backend)
	mut collection := api.all('articles')

	mut custom := collection.custom('special', true)
	assert custom.url() == 'http://api.example.com/articles/special'
}

fn test_member_one_with_params() {
	backend := EntityMockBackend{}
	mut api := restful.restful('http://api.example.com', backend)
	mut member := api.one('articles', '1')

	mut nested_member := member.one('comments', '5')
	assert nested_member.url() == 'http://api.example.com/articles/1/comments/5'
}

fn test_member_all_with_params() {
	backend := EntityMockBackend{}
	mut api := restful.restful('http://api.example.com', backend)
	mut member := api.one('articles', '1')

	mut collection := member.all('comments')
	assert collection.url() == 'http://api.example.com/articles/1/comments'
}

fn test_member_custom_with_params() {
	backend := EntityMockBackend{}
	mut api := restful.restful('http://api.example.com', backend)
	mut member := api.one('articles', '1')

	mut custom := member.custom('special', true)
	assert custom.url() == 'http://api.example.com/articles/1/special'
}

fn test_entity_data_structure() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"id": "1", "title": "Test", "nested": {"key": "value"}, "array": [1, 2, 3]}'
        }
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut member := api.one('articles', '1')

    mut entity := member.get(map[string]string{}, map[string]string{})!
    data := entity.data()

    assert data['id'] == json.Any('1')
    assert data['title'] == json.Any('Test')
    assert data['nested'] == json.Any({
        'key': json.Any('value')
    })
    assert data['array'] == json.Any([json.Any(1), json.Any(2), json.Any(3)])
}

fn test_collection_get_all_structure() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '[{"id": "1", "title": "Test 1"}, {"id": "2", "title": "Test 2"}]'
        }
    }

    mut api := restful.restful('http://api.example.com', backend)
    mut collection := api.all('articles')

    entities := collection.get_all(map[string]string{}, map[string]string{})!

    assert entities.len == 2
    assert entities[0].data()['id'] == json.Any('1')
    assert entities[1].data()['id'] == json.Any('2')
}

fn test_entity_url_inheritance() {
    backend := EntityMockBackend{}
    mut api := restful.restful('http://api.example.com', backend)

    mut articles := api.all('articles')
    mut article := articles.one('comments', '5')
    mut authors := article.all('authors')

    assert authors.url() == 'http://api.example.com/articles/5/comments/authors'
}

fn test_entity_custom_url() {
    backend := EntityMockBackend{}
    mut api := restful.restful('http://api.example.com', backend)

    mut custom := api.custom('special/endpoint', true)
    assert custom.url() == 'http://api.example.com/special/endpoint'

    mut absolute := api.custom('http://custom.url/endpoint', false)
    assert absolute.url() == 'http://custom.url/endpoint'
}

fn test_entity_identifier_inheritance() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '{"_id": "abc123", "title": "Test"}'
        }
    }

    mut api := restful.restful('http://api.example.com', backend)
    api.identifier('_id')

    mut articles := api.all('articles')
    articles.identifier('_id')

    mut entity := articles.get('abc123', map[string]string{}, map[string]string{})!
    assert entity.id() == 'abc123'
}

fn test_entity_header_inheritance() {
    backend := EntityMockBackend{}
    mut api := restful.restful('http://api.example.com', backend)
    api.header('AuthToken', 'test-token')

    mut articles := api.all('articles')
    articles.header('X-Custom', 'value')

    // Headers should be inherited
    assert articles.headers()['AuthToken'] == 'test-token'
    assert articles.headers()['X-Custom'] == 'value'
}

fn test_entity_event_propagation() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '[]'
        }
    }

    mut api := restful.restful('http://api.example.com', backend)

    mut request_count := 0
    mut response_count := 0

    api.on('request', fn [mut request_count] (data restful.EventData) {
        request_count++
    })

    api.on('response', fn [mut response_count] (data restful.EventData) {
        response_count++
    })

    mut articles := api.all('articles')
    articles.get_all(map[string]string{}, map[string]string{})!

    assert request_count == 1
    assert response_count == 1
}

fn test_entity_interceptor_inheritance() {
    mut backend := EntityMockBackend{
        response: restful.Response{
            status_code: 200
            headers:     {
                'Content-Type': 'application/json'
            }
            body:        '[]'
        }
    }

    mut api := restful.restful('http://api.example.com', backend)

    mut api_request_called := false
    mut collection_request_called := false

    api.add_request_interceptor(fn [mut api_request_called] (config restful.RequestConfig) restful.RequestConfig {
        api_request_called = true
        return config
    })

    mut articles := api.all('articles')
    articles.add_request_interceptor(fn [mut collection_request_called] (config restful.RequestConfig) restful.RequestConfig {
        collection_request_called = true
        return config
    })

    articles.get_all(map[string]string{}, map[string]string{})!

    assert api_request_called
    assert collection_request_called
}
