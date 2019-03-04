import * as React from 'react';
import { render, cleanup } from 'react-testing-library';
import Layout from '../../components/Layout';

afterEach(cleanup);

describe('Layout component', () => {
  test('should render correctly', () => {
    const title = 'Panvala';
    const layout = render(<Layout title={title} />);
    expect(layout.container).toMatchSnapshot();
  });

  test.todo('should sort proposals in the correct order by: createdAt');
});
