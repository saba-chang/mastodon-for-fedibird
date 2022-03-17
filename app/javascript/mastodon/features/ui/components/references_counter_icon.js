import { connect } from 'react-redux';
import IconWithBadge from 'mastodon/components/icon_with_badge';
import { maxReferences } from '../../../initial_state';

const mapStateToProps = state => ({
  count: state.getIn(['compose', 'references']).count(),
  countMax: maxReferences,
  id: 'link',
});

export default connect(mapStateToProps)(IconWithBadge);
