import 'package:querycraft/querycraft.dart';
import 'package:test/test.dart';

void main() {
  test('ApiQueryFiltering with invalid operation should throw an exception',
      () {
    final expectedJson =  {
      'filtering': '{"condition":"and","filtering":[{"by":"field1","op":"eq","match":"value1"},{"by":"field2","op":"eq","match":"value2"}],"groups":[{"condition":"or","filtering":[{"by":"field3","op":"eq","match":"value3"},{"by":"field4","op":"eq","match":"value4"}],"groups":[]},{"condition":"or","filtering":[{"by":"field3","op":"eq","match":"value3"},{"by":"field4","op":"eq","match":"value4"}],"groups":[]}]}',
      'paging': '{"offset":20,"limit":0}',
      'ordering': '[{"by":"name","dir":"asc"}]'
    };

    final query = ApiQuery(
      filtering: and(
        filters: [
          where('field1', 'eq', 'value1'),
          where('field2', 'eq', 'value2'),
        ],
        groups: [
          or(
            filters: [
              where('field3', 'eq', 'value3'),
              where('field4', 'eq', 'value4'),
            ],
          ),
          or(
            filters: [
              where('field3', 'eq', 'value3'),
              where('field4', 'eq', 'value4'),
            ],
          ),
        ],
      ),
      ordering: [
        ordering('name', QueryOrderDirection.asc),
      ],
      paging: paginate(limit: 0, offset: 20),
    );

    expect(query.toMap(), equals(expectedJson));
  });
}
