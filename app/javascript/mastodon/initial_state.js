const element = document.getElementById('initial-state');
const initialState = element && JSON.parse(element.textContent);

const getMeta = (prop) => initialState && initialState.meta && initialState.meta[prop];

export const reduceMotion = getMeta('reduce_motion');
export const autoPlayGif = getMeta('auto_play_gif');
export const displayMedia = getMeta('display_media');
export const expandSpoilers = getMeta('expand_spoilers');
export const unfollowModal = getMeta('unfollow_modal');
export const unsubscribeModal = getMeta('unsubscribe_modal');
export const boostModal = getMeta('boost_modal');
export const deleteModal = getMeta('delete_modal');
export const postReferenceModal = getMeta('post_reference_modal');
export const addReferenceModal = getMeta('add_reference_modal');
export const unselectReferenceModal = getMeta('unselect_reference_modal');
export const me = getMeta('me');
export const searchEnabled = getMeta('search_enabled');
export const invitesEnabled = getMeta('invites_enabled');
export const limitedFederationMode = getMeta('limited_federation_mode');
export const repository = getMeta('repository');
export const source_url = getMeta('source_url');
export const version = getMeta('version');
export const mascot = getMeta('mascot');
export const profile_directory = getMeta('profile_directory');
export const isStaff = getMeta('is_staff');
export const forceSingleColumn = !getMeta('advanced_layout');
export const useBlurhash = getMeta('use_blurhash');
export const usePendingItems = getMeta('use_pending_items');
export const showTrends = getMeta('trends');
export const title = getMeta('title');
export const cropImages = getMeta('crop_images');
export const disableSwiping = getMeta('disable_swiping');
export const show_follow_button_on_timeline = getMeta('show_follow_button_on_timeline');
export const show_subscribe_button_on_timeline = getMeta('show_subscribe_button_on_timeline');
export const show_followed_by = getMeta('show_followed_by');
export const follow_button_to_list_adder = getMeta('follow_button_to_list_adder');
export const show_navigation_panel = getMeta('show_navigation_panel');
export const show_quote_button = getMeta('show_quote_button');
export const show_bookmark_button = getMeta('show_bookmark_button');
export const show_target = getMeta('show_target');
export const place_tab_bar_at_bottom = getMeta('place_tab_bar_at_bottom');
export const show_tab_bar_label = getMeta('show_tab_bar_label');
export const enable_limited_timeline = getMeta('enable_limited_timeline');
export const enableReaction = getMeta('enable_reaction');
export const compactReaction = getMeta('compact_reaction');
export const show_reply_tree_button = getMeta('show_reply_tree_button');
export const disable_joke_appearance = getMeta('disable_joke_appearance');
export const new_features_policy = getMeta('new_features_policy');
export const enableStatusReference = getMeta('enable_status_reference');
export const maxReferences = initialState?.status_references?.max_references;
export const matchVisibilityOfReferences = getMeta('match_visibility_of_references');
export const enableEmptyColumn = getMeta('enable_empty_column');

export default initialState;
