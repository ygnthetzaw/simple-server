const AccessTree = function () {
  const self = this;
  const ACCESS_ITEM_SELECTOR = ".access-item";

  const hierarchy = {
    organization: {
      child: "facilityGroup",
      parent: null,
    },
    facilityGroup: {
      child: "facility",
      parent: "organization",
    },
    facility: {
      parent: "facilityGroup",
      child: null,
    },
  };

  function getChildKey(accessType) {
    return hierarchy[accessType] && hierarchy[accessType].child;
  }

  function getParentKey(accessType) {
    return hierarchy[accessType] && hierarchy[accessType].parent;
  }

  function addAccessItemMetaData(accessGroup, accessItem, _key) {
    const accessType = accessItem.dataset.accessType;
    const parentKey = getParentKey(accessType);
    const parentId = accessItem.dataset[parentKey];
    return (accessGroup[accessItem.dataset.id] = {
      element: accessItem,
      [parentKey]: parentId,
      name: accessItem.dataset.name,
      accessType,
      parent: getAccessItemParent(accessType, parentId),
      children: getAccessItemChildren(accessType, accessItem.dataset.id),
      siblings: getAccessItemSiblings(accessType, accessItem.dataset.id)
    });
  }

  function getAccessItemSiblings(accessType, itemId) {
    return function () {
      const tree = self.accessTree;
      if (_.isNull(hierarchy[accessType].parent)) {
        return Object.values(tree[accessType]);
      }
      const accessItem = tree[accessType][itemId]
      return accessItem.parent().children()
    };
  }

  function getAccessItemParent(accessType, parentId) {
    return function () {
      const tree = self.accessTree;
      const parentIdentifierKey = getParentKey(accessType);
      if (!parentIdentifierKey) return;
      return tree[parentIdentifierKey][parentId];
    };
  }

  function getAccessItemChildren(accessType, itemId) {
    return function () {
      const tree = self.accessTree;
      const childKey = getChildKey(accessType);
      const parentIdKey = getParentKey(childKey);
      if (!childKey) return;
      return Object.values(tree[childKey])
        .filter(item => item[parentIdKey] === itemId);
    };
  }

  function buildAccessTree() {
    const accessItems = Array.from(document.querySelectorAll(ACCESS_ITEM_SELECTOR));
    const data = _.groupBy(accessItems, (item) => item.dataset.accessType);
    return _.transform(
      data,
      (accessTree, accessGroup, accessType) => {
        accessTree[accessType] = _.transform(accessGroup, addAccessItemMetaData, {})
      }
    );
  }

  this.accessTree = buildAccessTree();

  return {
    organization: this.accessTree.organization,
    facility: this.accessTree.facility,
    facilityGroup: this.accessTree.facilityGroup,
  };
};

/**
 * Notes for integrating this with the admin.js
 * --------------------------------------------
 *
 * Running new AccessTree() would return a tree with accessItems grouped by
 * accessGroup (organization, facilityGroup, facility).
 *
 * The object would look something like this
 * ```Object { organization: {…}, facility: {…}, facilityGroup: {…} }```
 *
 * Each item in the accessGroup is a DOMElement element wrapped with some helper
 * functions, namely .parent(), .children(), .siblings() to help walk up and down
 * the tree.
 *
 * Adding a new hierarchy
 * ----------------------
 *
 * Adding the new hierarchy should be pretty straightforward. You'll need to
 * add it to the hierarchy object in AccessTree, and adding the following data
 * attributes to the new access item partial: data-<parent-access-type>,
 * data-access-type, data-id, data-name
 *
 * data-<parent-access-type> holds the ID of the parent
 * 
 * That should be it.
 * Cheers!
 */