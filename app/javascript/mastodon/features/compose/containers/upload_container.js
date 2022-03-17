import { connect } from 'react-redux';
import Upload from '../components/upload';
import { undoUploadCompose, initMediaEditModal } from '../../../actions/compose';
import { submitComposeWithCheck } from '../../../actions/compose';
import { injectIntl } from 'react-intl';

const mapStateToProps = (state, { id }) => ({
  media: state.getIn(['compose', 'media_attachments']).find(item => item.get('id') === id),
});

const mapDispatchToProps = (dispatch, { intl }) => ({

  onUndo: id => {
    dispatch(undoUploadCompose(id));
  },

  onOpenFocalPoint: id => {
    dispatch(initMediaEditModal(id));
  },

  onSubmit (router) {
    dispatch(submitComposeWithCheck(router, intl));
  },

});

export default injectIntl(connect(mapStateToProps, mapDispatchToProps)(Upload));
