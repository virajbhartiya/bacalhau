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

class StateExecutionStateType(object):
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
        'message': 'str',
        'state_type': 'AllOfStateExecutionStateTypeStateType'
    }

    attribute_map = {
        'message': 'Message',
        'state_type': 'StateType'
    }

    def __init__(self, message=None, state_type=None):  # noqa: E501
        """StateExecutionStateType - a model defined in Swagger"""  # noqa: E501
        self._message = None
        self._state_type = None
        self.discriminator = None
        if message is not None:
            self.message = message
        if state_type is not None:
            self.state_type = state_type

    @property
    def message(self):
        """Gets the message of this StateExecutionStateType.  # noqa: E501

        Message is a human readable message describing the state.  # noqa: E501

        :return: The message of this StateExecutionStateType.  # noqa: E501
        :rtype: str
        """
        return self._message

    @message.setter
    def message(self, message):
        """Sets the message of this StateExecutionStateType.

        Message is a human readable message describing the state.  # noqa: E501

        :param message: The message of this StateExecutionStateType.  # noqa: E501
        :type: str
        """

        self._message = message

    @property
    def state_type(self):
        """Gets the state_type of this StateExecutionStateType.  # noqa: E501

        StateType is the current state of the object.  # noqa: E501

        :return: The state_type of this StateExecutionStateType.  # noqa: E501
        :rtype: AllOfStateExecutionStateTypeStateType
        """
        return self._state_type

    @state_type.setter
    def state_type(self, state_type):
        """Sets the state_type of this StateExecutionStateType.

        StateType is the current state of the object.  # noqa: E501

        :param state_type: The state_type of this StateExecutionStateType.  # noqa: E501
        :type: AllOfStateExecutionStateTypeStateType
        """

        self._state_type = state_type

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
        if issubclass(StateExecutionStateType, dict):
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
        if not isinstance(other, StateExecutionStateType):
            return False

        return self.__dict__ == other.__dict__

    def __ne__(self, other):
        """Returns true if both objects are not equal"""
        return not self == other
