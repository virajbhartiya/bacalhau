# coding: utf-8

"""
    Bacalhau API

    This page is the reference of the Bacalhau REST API. Project docs are available at https://docs.bacalhau.org/. Find more information about Bacalhau at https://github.com/bacalhau-project/bacalhau.  # noqa: E501

    OpenAPI spec version: ${VERSION}
    Contact: team@bacalhau.org
    Generated by: https://github.com/swagger-api/swagger-codegen.git
"""

import pprint
import re  # noqa: F401

import six

class ApiListJobExecutionsResponse(object):
    """NOTE: This class is auto generated by the swagger code generator program.

    Do not edit the class manually.
    """
    """
    Attributes:
      swagger_types (dict): The key is attribute name
                            and the value is attribute type.
      attribute_map (dict): The key is attribute name
                            and the value is json key in definition.
    """
    swagger_types = {
        'items': 'list[Execution]',
        'next_token': 'str'
    }

    attribute_map = {
        'items': 'Items',
        'next_token': 'NextToken'
    }

    def __init__(self, items=None, next_token=None):  # noqa: E501
        """ApiListJobExecutionsResponse - a model defined in Swagger"""  # noqa: E501
        self._items = None
        self._next_token = None
        self.discriminator = None
        if items is not None:
            self.items = items
        if next_token is not None:
            self.next_token = next_token

    @property
    def items(self):
        """Gets the items of this ApiListJobExecutionsResponse.  # noqa: E501


        :return: The items of this ApiListJobExecutionsResponse.  # noqa: E501
        :rtype: list[Execution]
        """
        return self._items

    @items.setter
    def items(self, items):
        """Sets the items of this ApiListJobExecutionsResponse.


        :param items: The items of this ApiListJobExecutionsResponse.  # noqa: E501
        :type: list[Execution]
        """

        self._items = items

    @property
    def next_token(self):
        """Gets the next_token of this ApiListJobExecutionsResponse.  # noqa: E501


        :return: The next_token of this ApiListJobExecutionsResponse.  # noqa: E501
        :rtype: str
        """
        return self._next_token

    @next_token.setter
    def next_token(self, next_token):
        """Sets the next_token of this ApiListJobExecutionsResponse.


        :param next_token: The next_token of this ApiListJobExecutionsResponse.  # noqa: E501
        :type: str
        """

        self._next_token = next_token

    def to_dict(self):
        """Returns the model properties as a dict"""
        result = {}

        for attr, _ in six.iteritems(self.swagger_types):
            value = getattr(self, attr)
            if isinstance(value, list):
                result[attr] = list(map(
                    lambda x: x.to_dict() if hasattr(x, "to_dict") else x,
                    value
                ))
            elif hasattr(value, "to_dict"):
                result[attr] = value.to_dict()
            elif isinstance(value, dict):
                result[attr] = dict(map(
                    lambda item: (item[0], item[1].to_dict())
                    if hasattr(item[1], "to_dict") else item,
                    value.items()
                ))
            else:
                result[attr] = value
        if issubclass(ApiListJobExecutionsResponse, dict):
            for key, value in self.items():
                result[key] = value

        return result

    def to_str(self):
        """Returns the string representation of the model"""
        return pprint.pformat(self.to_dict())

    def __repr__(self):
        """For `print` and `pprint`"""
        return self.to_str()

    def __eq__(self, other):
        """Returns true if both objects are equal"""
        if not isinstance(other, ApiListJobExecutionsResponse):
            return False

        return self.__dict__ == other.__dict__

    def __ne__(self, other):
        """Returns true if both objects are not equal"""
        return not self == other
