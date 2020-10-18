const AccessTree = function () {
  const self = this;

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

  function addAccessItemMetaData(result, accessItem, _key) {
    const accessType = accessItem.dataset.accessType;
    const parentKey = getParentKey(accessType);
    const parentId = accessItem.dataset[parentKey];
    return (result[accessItem.dataset.id] = {
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
      return Object.values(tree[childKey]).filter(
        (item) => item[parentIdKey] === itemId
      );
    };
  }

  function buildAccessTree() {
    const accessItems = Array.from(document.querySelectorAll(".access-item"));
    const data = _.groupBy(accessItems, (item) => item.dataset.accessType);
    return _.transform(
      data,
      (result, accessItem, key) =>
        (result[key] = _.transform(accessItem, addAccessItemMetaData, {}))
    );
  }

  this.accessTree = buildAccessTree();

  return {
    organization: this.accessTree.organization,
    facility: this.accessTree.facility,
    facilityGroup: this.accessTree.facilityGroup,
  };
};
